module Nameservice.Modules.Nameservice.Query where

import           Data.Proxy
import           Nameservice.Modules.Nameservice.Keeper (storeKey)
import           Nameservice.Modules.Nameservice.Types  (Name, Whois)
import           Polysemy                               (Members)
import           Polysemy.Error                         (Error)
import qualified Tendermint.SDK.BaseApp                 as BaseApp

--------------------------------------------------------------------------------
-- | Query API
--------------------------------------------------------------------------------

type NameserviceContents = '[(Name, Whois)]

type QueryApi = BaseApp.QueryApi NameserviceContents

server
  :: Members [BaseApp.RawStore, Error BaseApp.AppError] r
  => BaseApp.RouteQ QueryApi r
server =
  BaseApp.storeQueryHandlers (Proxy :: Proxy NameserviceContents) storeKey (Proxy :: Proxy r)
