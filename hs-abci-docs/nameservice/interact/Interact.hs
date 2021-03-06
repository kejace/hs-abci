module Interact
  ( actionBlock
  , makeRandomUsers
  ) where

import           Control.Monad                     (replicateM, void)
import           Control.Monad.Reader              (ReaderT, runReaderT)
import           Data.Char                         (isHexDigit)
import           Data.Default.Class                (def)
import           Data.Proxy
import           Data.String                       (fromString)
import           Data.String.Conversions           (cs)
import           Data.Text                         (Text)
import qualified Faker.Lorem                       as Lorem
import qualified Faker.Name                        as Name
import qualified Faker.Utils                       as Utils
import           Nameservice.Application
import qualified Nameservice.Modules.Nameservice   as N
import qualified Nameservice.Modules.Token         as T
import qualified Network.Tendermint.Client         as RPC
import           Servant.API                       ((:<|>) (..))
import           Tendermint.SDK.Application.Module (AppQueryRouter (QApi),
                                                    AppTxRouter (TApi))
import           Tendermint.SDK.BaseApp.Errors     (AppError (..))
import           Tendermint.SDK.BaseApp.Query      (QueryArgs (..),
                                                    QueryResult (..))
import qualified Tendermint.SDK.Modules.Auth       as Auth
import           Tendermint.SDK.Types.Address      (Address)
import           Tendermint.Utils.Client           (ClientConfig (..),
                                                    EmptyTxClient (..),
                                                    HasQueryClient (..),
                                                    HasTxClient (..),
                                                    QueryClientResponse (..),
                                                    Signer (..),
                                                    TxClientResponse (..),
                                                    TxOpts (..),
                                                    defaultClientTxOpts)
import           Tendermint.Utils.ClientUtils      (assertTx, rpcConfig)
import           Tendermint.Utils.User             (makeSignerFromUser,
                                                    makeUser)
import           Test.RandomStrings                (onlyWith, randomASCII,
                                                    randomString)

--------------------------------------------------------------------------------
-- Actions
--------------------------------------------------------------------------------

faucetAccount :: Signer -> T.Amount -> IO ()
faucetAccount s@(Signer addr _) amount =
  runAction_ s faucet $ T.FaucetAccount addr amount

createName :: Signer -> N.Name -> Text -> IO ()
createName s name val = buyName s name val 0

buyName :: Signer -> N.Name -> Text -> T.Amount -> IO ()
buyName s@(Signer addr _) name newVal amount =
  runAction_ s buy $ N.BuyName amount name newVal addr

deleteName :: Signer -> N.Name -> IO ()
deleteName s@(Signer addr _) name =
  runAction_ s delete $ N.DeleteName addr name

setName :: Signer -> N.Name -> Text -> IO ()
setName s@(Signer addr _) name val =
  runAction_ s set $ N.SetName name addr val

runAction_
  :: Signer
  -> (TxOpts -> msg -> TxClientM (TxClientResponse () ()))
  -> msg
  -> IO ()
runAction_ s f = void . assertTx . runTxClientM . f (TxOpts 0 s)

actionBlock :: (Signer, Signer) -> IO ()
actionBlock (s1, s2) = do
  name <- genName
  genCVal <- genWords
  genBVal <- genWords
  genBAmt <- genAmount
  genSVal <- genWords
  faucetAccount s2 genBAmt
  createName s1 name genCVal
  buyName s2 name genBVal genBAmt
  setName s2 name genSVal
  deleteName s2 name

--------------------------------------------------------------------------------
-- Users
--------------------------------------------------------------------------------

makeRandomUsers :: IO (Signer, Signer)
makeRandomUsers = do
  str1 <- randomString (onlyWith isHexDigit randomASCII) 64
  str2 <- randomString (onlyWith isHexDigit randomASCII) 64
  return $ (makeSignerFromUser . makeUser $ str1
           ,makeSignerFromUser . makeUser $ str2
           )

--------------------------------------------------------------------------------
-- Query Client
--------------------------------------------------------------------------------

getAccount
  :: QueryArgs Address
  -> RPC.TendermintM (QueryClientResponse Auth.Account)

_ :<|> _ :<|> getAccount =
  genClientQ (Proxy :: Proxy m) queryApiP def
  where
    queryApiP :: Proxy (QApi NameserviceModules)
    queryApiP = Proxy

 --------------------------------------------------------------------------------
-- Tx Client
--------------------------------------------------------------------------------

txClientConfig :: ClientConfig
txClientConfig =
  let getNonce addr = do
        resp <- RPC.runTendermintM rpcConfig $ getAccount $
          QueryArgs
            { queryArgsHeight = -1
            , queryArgsProve = False
            , queryArgsData = addr
            }
        case resp of
          QueryError e ->
            if appErrorCode e == 2
              then pure 0
              else error $ "Unknown nonce error: " <> show (appErrorMessage e)
          QueryResponse QueryResult {queryResultData} ->
            pure $ Auth.accountNonce queryResultData

  in ClientConfig
       { clientGetNonce = getNonce
       , clientRPC = rpcConfig
       }

type TxClientM = ReaderT ClientConfig IO

runTxClientM :: TxClientM a -> IO a
runTxClientM m = runReaderT m txClientConfig

-- Nameservice Client
buy
  :: TxOpts
  -> N.BuyName
  -> TxClientM (TxClientResponse () ())

set
  :: TxOpts
  -> N.SetName
  -> TxClientM (TxClientResponse () ())

delete
  :: TxOpts
  -> N.DeleteName
  -> TxClientM (TxClientResponse () ())

-- Token Client
faucet
  :: TxOpts
  -> T.FaucetAccount
  -> TxClientM (TxClientResponse () ())

(buy :<|> set :<|> delete) :<|>
  (_ :<|> _ :<|> faucet) :<|>
  EmptyTxClient =
    genClientT (Proxy @TxClientM) txApiP defaultClientTxOpts
    where
      txApiP :: Proxy (TApi NameserviceModules)
      txApiP = Proxy


--------------------------------------------------------------------------------
-- Generation
--------------------------------------------------------------------------------

genWords :: IO Text
genWords = do
  numWords <- Utils.randomNum (1, 10)
  ws <- replicateM numWords Lorem.word
  return . cs . unwords $ ws

genName :: IO N.Name
genName = do
  name <- Name.name
  return . fromString $ name

genAmount :: IO T.Amount
genAmount = do
  genAmt <- Utils.randomNum (1, 1000)
  return . fromInteger . toInteger $ genAmt
