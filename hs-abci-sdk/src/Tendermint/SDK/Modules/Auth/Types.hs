{-# OPTIONS_GHC -fno-warn-orphans #-}

module Tendermint.SDK.Modules.Auth.Types where

import           Control.Lens                 (Wrapped (..), from, iso, view,
                                               (&), (.~), (^.), (^..),
                                               _Unwrapped')
import           Data.Bifunctor               (bimap)
import qualified Data.ProtoLens               as P
import           Data.Proxy                   (Proxy (..))
import           Data.String.Conversions      (cs)
import           Data.Text                    (Text)
import           Data.Word
import           GHC.Generics                 (Generic)
import           GHC.TypeLits                 (symbolVal)
import qualified Proto.Modules.Auth           as A
import qualified Proto.Modules.Auth_Fields    as A
import           Tendermint.SDK.BaseApp       (AppError (..), IsAppError (..),
                                               IsKey (..), Queryable (..))
import           Tendermint.SDK.Codec         (HasCodec (..))
import           Tendermint.SDK.Types.Address (Address)

type AuthModule = "auth"

data Coin = Coin
  { coinDenomination :: Text
  , coinAmount       :: Word64
  } deriving Generic

instance Wrapped Coin where
  type Unwrapped Coin = A.Coin

  _Wrapped' = iso t f
   where
    t Coin {..} =
      P.defMessage
        & A.denomination .~ coinDenomination
        & A.amount .~ coinAmount
    f message = Coin
      { coinDenomination = message ^. A.denomination
      , coinAmount = message ^. A.amount
      }

data Account = Account
  { accountCoins :: [Coin]
  , accountNonce :: Word64
  } deriving Generic

instance Wrapped Account where
  type Unwrapped Account = A.Account

  _Wrapped' = iso t f
   where
    t Account {..} =
      P.defMessage
        & A.coins .~ accountCoins ^.. traverse . _Wrapped'
        & A.nonce .~ accountNonce
    f message = Account
      { accountCoins = message ^.. A.coins. traverse . _Unwrapped'
      , accountNonce = message ^. A.nonce
      }

instance HasCodec Account where
  encode = P.encodeMessage . view _Wrapped'
  decode = bimap cs (view $ from _Wrapped') . P.decodeMessage

instance IsKey Address AuthModule where
    type Value Address AuthModule = Account

instance Queryable Account where
  type Name Account = "account"

data AuthError =
  AccountAlreadExists Address

instance IsAppError AuthError where
  makeAppError (AccountAlreadExists addr) =
    AppError
      { appErrorCode = 1
      , appErrorCodespace = cs (symbolVal $ Proxy @AuthModule)
      , appErrorMessage = "Account Already Exists " <> (cs . show $ addr) <> "."
      }
