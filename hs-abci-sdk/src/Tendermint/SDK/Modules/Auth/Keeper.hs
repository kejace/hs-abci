{-# LANGUAGE TemplateHaskell #-}

module Tendermint.SDK.Modules.Auth.Keeper where

import           Polysemy
import           Polysemy.Error                    (Error)
import           Tendermint.SDK.BaseApp            (AppError, RawStore,
                                                    StoreKey (..), get, put)
import           Tendermint.SDK.Modules.Auth.Types
import           Tendermint.SDK.Types.Address      (Address)

data Accounts m a where
  PutAccount :: Address -> Account -> Accounts m ()
  GetAccount :: Address -> Accounts m (Maybe Account)

makeSem ''Accounts

type AuthEffs = '[Accounts]

storeKey :: StoreKey AuthModule
storeKey = StoreKey "auth"

eval
  :: Members [RawStore, Error AppError] r
  => Sem (Accounts : r) a
  -> Sem r a
eval =
  interpret (\case
      GetAccount addr ->
        get storeKey addr
      PutAccount addr acnt ->
        put storeKey addr acnt
    )