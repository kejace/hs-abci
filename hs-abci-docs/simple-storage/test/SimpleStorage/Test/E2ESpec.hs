module SimpleStorage.Test.E2ESpec (spec) where

import           Control.Monad.Reader                (ReaderT, runReaderT)
import           Data.Default.Class                  (def)
import           Data.Proxy
import qualified Network.Tendermint.Client           as RPC
import           Servant.API                         ((:<|>) (..))
import           SimpleStorage.Application
import qualified SimpleStorage.Modules.SimpleStorage as SS
import           Tendermint.SDK.Application.Module   (AppQueryRouter (QApi),
                                                      AppTxRouter (TApi))
import           Tendermint.SDK.BaseApp.Errors       (AppError (..))
import           Tendermint.SDK.BaseApp.Query        (QueryArgs (..),
                                                      QueryResult (..),
                                                      defaultQueryArgs)
import qualified Tendermint.SDK.Modules.Auth         as Auth
import           Tendermint.SDK.Types.Address        (Address)
import           Tendermint.Utils.Client             (ClientConfig (..),
                                                      EmptyTxClient (..),
                                                      HasQueryClient (..),
                                                      HasTxClient (..),
                                                      QueryClientResponse (..),
                                                      TxClientResponse (..),
                                                      TxOpts (..),
                                                      defaultClientTxOpts)
import           Tendermint.Utils.ClientUtils        (assertQuery, assertTx,
                                                      ensureResponseCodes,
                                                      rpcConfig)
import           Tendermint.Utils.User               (User (..),
                                                      makeSignerFromUser,
                                                      makeUser)
import           Test.Hspec

spec :: Spec
spec = do
  describe "SimpleStorage E2E - via hs-tendermint-client" $ do

    it "Can query /health to make sure the node is alive" $ do
      resp <- RPC.runTendermintM rpcConfig RPC.health
      resp `shouldBe` RPC.ResultHealth

    it "Can submit a tx synchronously and make sure that the response code is 0 (success)" $ do
      let txOpts = TxOpts
            { txOptsGas = 0
            , txOptsSigner = makeSignerFromUser user1
            }
          tx = SS.UpdateCountTx
                 { SS.updateCountTxUsername = "charles"
                 , SS.updateCountTxCount = 4
                 }
      resp <- assertTx . runTxClientM $ updateCount txOpts tx
      ensureResponseCodes (0,0) resp

    it "can make sure the synchronous tx transaction worked and the count is now 4" $ do
      resp <-  assertQuery . RPC.runTendermintM rpcConfig $
        getCount defaultQueryArgs { queryArgsData = SS.CountKey }
      let foundCount = queryResultData resp
      foundCount `shouldBe` SS.Count 4

--------------------------------------------------------------------------------
-- Query Client
--------------------------------------------------------------------------------

getCount
  :: QueryArgs SS.CountKey
  -> RPC.TendermintM (QueryClientResponse SS.Count)

getAccount
  :: QueryArgs Address
  -> RPC.TendermintM (QueryClientResponse Auth.Account)

getCount :<|> getAccount =
  genClientQ (Proxy :: Proxy m) queryApiP def
  where
    queryApiP :: Proxy (QApi SimpleStorageModules)
    queryApiP = Proxy


--------------------------------------------------------------------------------
-- Tx Client
--------------------------------------------------------------------------------

txClientConfig :: ClientConfig
txClientConfig =
  let getNonce addr = do
        resp <- RPC.runTendermintM rpcConfig $ getAccount $
            defaultQueryArgs { queryArgsData = addr }
        case resp of
          QueryError e ->
            if appErrorCode e == 2
              then pure 0
              else error $ "Unknown nonce error: " <> show (appErrorMessage e)
          QueryResponse QueryResult{queryResultData} ->
            pure $ Auth.accountNonce queryResultData

  in ClientConfig
       { clientGetNonce = getNonce
       , clientRPC = rpcConfig
       }

type TxClientM = ReaderT ClientConfig IO

runTxClientM :: TxClientM a -> IO a
runTxClientM m = runReaderT m txClientConfig

updateCount
  :: TxOpts
  -> SS.UpdateCountTx
  -> TxClientM (TxClientResponse () ())

updateCount :<|> EmptyTxClient =
  genClientT (Proxy @TxClientM) txApiP defaultClientTxOpts
  where
    txApiP :: Proxy (TApi SimpleStorageModules)
    txApiP = Proxy


--------------------------------------------------------------------------------

user1 :: User
user1 = makeUser "f65255094d7773ed8dd417badc9fc045c1f80fdc5b2d25172b031ce6933e039a"
