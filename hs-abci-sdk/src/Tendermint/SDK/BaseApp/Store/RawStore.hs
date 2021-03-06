{-# LANGUAGE TemplateHaskell #-}

module Tendermint.SDK.BaseApp.Store.RawStore
  ( RawStore(..)
  , RawKey(..)
  , IsKey(..)
  , StoreKey(..)
  , get
  , put
  , delete
  , prove
  , storeRoot
  , withTransaction
  , withSandbox
  , beginBlock
  , commitBlock
  ) where

import           Control.Lens                  (Iso', iso, (^.))
import qualified Data.ByteString               as BS
import           Data.Proxy
import           Data.String.Conversions       (cs)
import           Polysemy                      (Member, Members, Sem, makeSem)
import           Polysemy.Error                (Error, catch, throw)
import           Polysemy.Resource             (Resource, finally, onException)
import           Tendermint.SDK.BaseApp.Errors (AppError, SDKError (ParseError),
                                                throwSDKError)
import           Tendermint.SDK.Codec          (HasCodec (..))
import           Tendermint.SDK.Types.Address  (Address, addressFromBytes,
                                                addressToBytes)

newtype StoreKey n = StoreKey BS.ByteString

data RawStore m a where
  RawStorePut   :: StoreKey ns -> BS.ByteString -> BS.ByteString -> RawStore m ()
  RawStoreGet   :: StoreKey ns -> BS.ByteString -> RawStore m (Maybe BS.ByteString)
  RawStoreDelete :: StoreKey ns -> BS.ByteString -> RawStore m ()
  RawStoreProve :: StoreKey ns -> BS.ByteString -> RawStore m (Maybe BS.ByteString)
  RawStoreRoot :: RawStore m BS.ByteString
  RawStoreBeginTransaction :: RawStore m ()
  RawStoreRollback :: RawStore m ()
  RawStoreCommit :: RawStore m ()

makeSem ''RawStore

class RawKey k where
  rawKey :: Iso' k BS.ByteString

instance RawKey Address where
    rawKey = iso addressToBytes addressFromBytes


class RawKey k => IsKey k ns where
  type Value k ns = a | a -> ns k
  prefixWith :: Proxy k -> Proxy ns -> BS.ByteString

  default prefixWith :: Proxy k -> Proxy ns -> BS.ByteString
  prefixWith _ _ = ""


put
  :: forall k r ns.
     IsKey k ns
  => HasCodec (Value k ns)
  => Member RawStore r
  => StoreKey ns
  -> k
  -> Value k ns
  -> Sem r ()
put sk k a =
  let key = prefixWith (Proxy @k) (Proxy @ns) <> k ^. rawKey
      val = encode a
  in rawStorePut sk key val

get
  :: forall k r ns.
     IsKey k ns
  => HasCodec (Value k ns)
  => Members [RawStore, Error AppError] r
  => StoreKey ns
  -> k
  -> Sem r (Maybe (Value k ns))
get sk k = do
  let key = prefixWith (Proxy @k) (Proxy @ns) <> k ^. rawKey
  mRes <- rawStoreGet sk key
  case mRes of
    Nothing -> pure Nothing
    Just raw -> case decode raw of
      Left e  -> throwSDKError (ParseError $ "Impossible codec error "  <> cs e)
      Right a -> pure $ Just a

delete
  :: forall k ns r.
     IsKey k ns
  => Member RawStore r
  => StoreKey ns
  -> k
  -> Sem r ()
delete sk k = rawStoreDelete sk $
  prefixWith (Proxy @k) (Proxy @ns) <> k ^. rawKey

prove
  :: forall k ns r.
     IsKey k ns
  => Member RawStore r
  => StoreKey ns
  -> k
  -> Sem r (Maybe BS.ByteString)
prove sk k = rawStoreProve sk $
  prefixWith (Proxy @k) (Proxy @ns) <> k ^. rawKey

beginBlock
  :: Member RawStore r
  => Sem r ()
beginBlock = rawStoreBeginTransaction

commitBlock
  :: Member RawStore r
  => Sem r ()
commitBlock = rawStoreCommit

storeRoot
  :: Member RawStore r
  => Sem r BS.ByteString
storeRoot = rawStoreRoot

withTransaction
  :: forall r a.
     Members [RawStore, Resource, Error AppError] r
  => Sem r a
  -> Sem r a
withTransaction m =
   let tryTx = m `catch` (\e -> rawStoreRollback *> throw e)
   in do
      rawStoreBeginTransaction
      onException (tryTx <* rawStoreCommit) rawStoreRollback

withSandbox
  :: forall r a.
     Members [RawStore, Resource, Error AppError] r
  => Sem r a
  -> Sem r a
withSandbox m =
   let tryTx = m `catch` (\e -> rawStoreRollback *> throw e)
   in do
      rawStoreBeginTransaction
      finally (tryTx <* rawStoreRollback) rawStoreRollback
