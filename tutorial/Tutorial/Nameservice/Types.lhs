<!doctype html>
<!--
  Minimal Mistakes Jekyll Theme 4.17.2 by Michael Rose
  Copyright 2013-2019 Michael Rose - mademistakes.com | @mmistakes
  Free for personal and commercial use under the MIT license
  https://github.com/mmistakes/minimal-mistakes/blob/master/LICENSE
-->
<html lang="en" class="no-js">
  <head>
    <meta charset="utf-8">

<!-- begin _includes/seo.html --><title>tutorial -</title>
<meta name="description" content="">



<meta property="og:type" content="website">
<meta property="og:locale" content="en_US">
<meta property="og:site_name" content="">
<meta property="og:title" content="tutorial">
<meta property="og:url" content="/hs-abci/tutorial/Tutorial/Nameservice/Types.lhs">













<link rel="canonical" href="/hs-abci/tutorial/Tutorial/Nameservice/Types.lhs">




<script type="application/ld+json">
  {
    "@context": "https://schema.org",
    
      "@type": "Person",
      "name": null,
      "url": "/hs-abci/"
    
  }
</script>






<!-- end _includes/seo.html -->


<link href="/hs-abci/feed.xml" type="application/atom+xml" rel="alternate" title=" Feed">

<!-- https://t.co/dKP3o1e -->
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<script>
  document.documentElement.className = document.documentElement.className.replace(/\bno-js\b/g, '') + ' js ';
</script>

<!-- For all browsers -->
<link rel="stylesheet" href="/hs-abci/assets/css/main.css">

<!--[if IE]>
  <style>
    /* old IE unsupported flexbox fixes */
    .greedy-nav .site-title {
      padding-right: 3em;
    }
    .greedy-nav button {
      position: absolute;
      top: 0;
      right: 0;
      height: 100%;
    }
  </style>
<![endif]-->



    <!-- start custom head snippets -->

<!-- insert favicons. use https://realfavicongenerator.net/ -->

<!-- end custom head snippets -->

  </head>

  <body class="layout--home">
    <nav class="skip-links">
  <h2 class="screen-reader-text">Skip links</h2>
  <ul>
    <li><a href="#site-nav" class="screen-reader-shortcut">Skip to primary navigation</a></li>
    <li><a href="#main" class="screen-reader-shortcut">Skip to content</a></li>
    <li><a href="#footer" class="screen-reader-shortcut">Skip to footer</a></li>
  </ul>
</nav>

    <!--[if lt IE 9]>
<div class="notice--danger align-center" style="margin: 0;">You are using an <strong>outdated</strong> browser. Please <a href="https://browsehappy.com/">upgrade your browser</a> to improve your experience.</div>
<![endif]-->

    

<div class="masthead">
  <div class="masthead__inner-wrap">
    <div class="masthead__menu">
      <nav id="site-nav" class="greedy-nav">
        
        <a class="site-title" href="/hs-abci/">
          
          
        </a>
        <ul class="visible-links"></ul>
        
        <button class="greedy-nav__toggle hidden" type="button">
          <span class="visually-hidden">Toggle menu</span>
          <div class="navicon"></div>
        </button>
        <ul class="hidden-links hidden"></ul>
      </nav>
    </div>
  </div>
</div>


    <div class="initial-content">
      



<div id="main" role="main">
  

  <div class="archive">
    
      <h1 id="page-title" class="page__title">tutorial</h1>
    
    # Types

The `Types` module is used to define the basic types that the module will make use of. This includes things like custom error types, event types, database types, etc. 

## Using A Typed Key Value Store
It is important to note that the database modeled by the `RawStore` effect (in the `BaseApp` type) is just a key value store for raw `ByteString`s. This means you can _think_ of `RawStore` as

```haskell
type RawStore = Map ByteString ByteString
```

although the definition of `RawStore` is different than the above.

The interface we give is actually a typed key value store. This means that within the scope of a module `m`, for any key type `k`, there is only one possible value type `v` associated with `k`. 

For example, a user's balance in the `Token` module, might be modeled by a mapping 

```haskell
balance :: Tendermint.SDK.Types.Address -> Integer
```

(We'll properly introduce the module `Token` later in the walkthrough.)

This means that in the scope of the `Token` module, the database utlity `get` function applied to a value of type `Address` will result in a value of type `Integer`. If the `Token` module would like to store another mapping whose keys have type `Tendermint.SDK.Types.Address`, you must use a newtype instead. Otherwise you will get a compiler error.

At the same time, you are free to define another mapping from `k -> v'` in the scope of a different module. For example, you can have both the `balance` mapping described above, as well a mapping 

```haskell
owner :: Tendermint.SDK.Types.Address -> Account
``` 
in the `Auth` module.

## Tutorial.Nameservice.Types

Let's look at the example in `Nameservice.Types`.

```haskell
module Tutorial.Nameservice.Types where

import Control.Lens (iso)
import qualified Data.Aeson as A
import Data.Bifunctor (first)
import Data.Proxy
import Data.String.Conversions (cs)
import Data.Text (Text)
import GHC.Generics (Generic)
import GHC.TypeLits (symbolVal)
import Nameservice.Aeson (defaultNameserviceOptions)
import Nameservice.Modules.Token (Amount)
import Proto3.Suite (Message, fromByteString, toLazyByteString)
import qualified Tendermint.SDK.BaseApp as BA
import Tendermint.SDK.Codec (HasCodec(..))
import Tendermint.SDK.Types.Address (Address)
import Tendermint.SDK.Types.Message (coerceProto3Error, formatMessageParseError)
```

### Storage types

Remember the `Nameservice` module is responsible for maintaining a marketplace around a mapping `Name -> Whois`. Let us define the types for the marketplace mapping as

```haskell
newtype Name = Name Text deriving (Eq, Show, Generic, A.ToJSON, A.FromJSON)

data Whois = Whois
  { whoisValue :: Text
  , whoisOwner :: Address
  , whoisPrice :: Amount
  } deriving (Eq, Show, Generic)
```

The way that we register `Name` as a key in the store is by using the `RawKey` typeclass

```haskell
class RawKey k where
  rawKey :: Iso' k ByteString
```

This class gives us a way to convert back and forth from a key to its encoding as a `ByteString`. In our case we implement

```haskell
-- here cs resolves to Data.Text.Encoding.encodeUtf8, Data.Text.Encoding.decodeUtf8 respectively
instance BA.RawKey Name where
    rawKey = iso (\(Name n) -> cs n) (Name . cs)
```

In order to register `Whois` as a storage type, we must implement the `HasCodec` typeclass

```haskell
class HasCodec a where
    encode :: a -> ByteString
    decode :: ByteString -> Either Text a
```

This class is used everywhere in the SDK as the binary codec class for things like storage items, messages, transaction formats etc. It's agnostic to the actual serialization format, you can use `JSON`, `CBOR`, `Protobuf`, etc. Throughout the SDK we typically use `protobuf` as it is powerful in addition to the fact that there's decent support for this in Haskell either through the `proto3-suite` package or the `proto-lens` package.

So we can implement a `HasCodec` instance for `Whois`

```haskell
-- Message is a class from proto3-suite that defines protobuf codecs generically.
instance Message Whois

instance HasCodec Whois where
  encode = cs . toLazyByteString
  decode = first (formatMessageParseError . coerceProto3Error) . fromByteString
```

Finally we can register `(Name, Whois)` with the module's store with the `IsKey` class, which tells how to associate a key type with a value type within the scope of given module, where the scope is represented by the modules name as a type level string. There is an optional prefixing function for the key in this context in order to avoid collisions in the database. This would be useful for example if you were using multiple newtyped `Address` types as keys in the same module.

```haskell
class RawKey k => IsKey k ns where
  type Value k ns = a | a -> ns k
  prefixWith :: Proxy k -> Proxy ns -> BS.ByteString

  default prefixWith :: Proxy k -> Proxy ns -> BS.ByteString
  prefixWith _ _ = ""
```

For the case of the `Name -> Whois` mapping, the `IsKey` instance looked like looks like this:

```haskell
type NameserviceModuleName = "nameservice"

instance BA.IsKey Name NameserviceModuleName where
  type Value Name NameserviceModuleName = Whois
```

At is point, you can use the database operations exported by `Tendermint.SDK.BaseApp.Store` such as `put`/`set`/`delete` for key value pairs of type `(Name, Whois)`.

### Query Types

The [`cosmos-sdk`](https://github.com/cosmos/cosmos-sdk) assumes that you use `url` formatted queries with some possible query params. For example, to query a `Whois` value based on a `Name`, you might submit a `query` message with the route `nameservice/whois` and supply a value of type `Name` to specify as the `data` field. Our SDK makes the same assumption for compatability reasons.

In order to register the `Whois` type with the query service, you must implement the `Queryable` typeclass:

```haskell
class Queryable a where
  type Name a :: Symbol
  encodeQueryResult :: a -> Base64String
  decodeQueryResult :: Base64String -> Either Text a

  default encodeQueryResult :: HasCodec a => a -> Base64String
  encodeQueryResult = fromBytes . encode

  default decodeQueryResult :: HasCodec a => Base64String -> Either Text a
  decodeQueryResult = decode . toByte
```

What this means is that you need to supply codecs for the type to query, with the default using the `HasCodec` class. You also need to name the type, as this will match the leaf of the `url` used for querying. So for example, in the Nameservice app we have

```haskell
instance BA.Queryable Whois where
  type Name Whois = "whois"
```

since `Whois` already implements the `HasCodec` class.

### Error Types

You might want to define a module specific error type that has a `throw`/`catch` interface. This error type should be accessible by any other dependent modules, and any uncaught error should eventually be converted into some kind of generic application error understandable by Tendermint. 

There is a simple way to do this using the `IsAppError` typeclass

```haskell
data AppError = AppError
  { appErrorCode      :: Word32
  , appErrorCodespace :: Text
  , appErrorMessage   :: Text
  } deriving Show

class IsAppError e where
  makeAppError :: e -> AppError
```

The fields for `AppError` correspond to tendermint message fields for messages that support error return types, such as `checkTx`, `deliverTx`, and `query`. Typically we use the module name as the codespace, like in the definition of `NamespaceError`:

```haskell
data NameserviceError =
    InsufficientBid Text
  | UnauthorizedSet Text
  | InvalidDelete Text

instance BA.IsAppError NameserviceError where
 -- remember 'symbolVal (Proxy @NameserviceModuleName)' resolves to "nameservice"
  makeAppError (InsufficientBid msg) =
    BA.AppError
      { appErrorCode = 1
      , appErrorCodespace = cs $ symbolVal (Proxy @NameserviceModuleName)
      , appErrorMessage = msg
      }
  makeAppError (UnauthorizedSet msg) =
    BA.AppError
      { appErrorCode = 2
      , appErrorCodespace = cs $ symbolVal (Proxy @NameserviceModuleName)
      , appErrorMessage = msg
      }
  makeAppError (InvalidDelete msg) =
    BA.AppError
      { appErrorCode = 3
      , appErrorCodespace = cs $ symbolVal (Proxy @NameserviceModuleName)
      , appErrorMessage = msg
      }
```

### Event Types
Tendermint has the capability to report event logs for transactions in the responses for both `checkTx` and `deliverTx` messages. The basic event type can be found in `Network.ABCI.Types.MessageFields`, it is simply a named key value mapping between `Bytestring`s:

```haskell
data Event = Event
  { eventType       :: Text
  -- ^ Type of Event
  , eventAttributes :: [KVPair]
  -- ^ Event attributes
  }

data KVPair = KVPair
  { kVPairKey   :: Base64String
  -- ^ key
  , kVPairValue :: Base64String
  -- ^ value
  }
```

Similar to the custom error messages, you can define custom events at the module level as long as they implement the `ToEvent` class to translate them to this standard type:

```haskell
class ToEvent e where
  makeEventType :: Proxy e -> String
  makeEventData :: e -> [(BS.ByteString, BS.ByteString)]

  default makeEventData :: A.ToJSON e => e -> [(BS.ByteString, BS.ByteString)]
  makeEventData e = case A.toJSON e of
    A.Object obj -> bimap cs (cs . A.encode) <$> toList obj
    _            -> mempty
```

As you can see, there is a default instance for those types which have a `JSON` representation as an `Object`. The reason that we chose a `JSON` default instance is simply because of support for generics, but this isn't set in stone.

In the case of `Nameservice`, here is an example of a custom event:

```haskell
data NameClaimed = NameClaimed
  { nameClaimedOwner :: Address
  , nameClaimedName  :: Name
  , nameClaimedValue :: Text
  , nameClaimedBid   :: Amount
  } deriving (Eq, Show, Generic)

-- 'defaultNameserviceOptions' is used to remove the record accessor prefix.
nameClaimedAesonOptions :: A.Options
nameClaimedAesonOptions = defaultNameserviceOptions "nameClaimed"

instance A.ToJSON NameClaimed where
  toJSON = A.genericToJSON nameClaimedAesonOptions

instance A.FromJSON NameClaimed where
  parseJSON = A.genericParseJSON nameClaimedAesonOptions

instance BA.ToEvent NameClaimed where
  makeEventType _ = "NameClaimed"
```

[Next: Message](Message.md)


<h3 class="archive__subtitle">Recent Posts</h3>






  </div>
</div>
    </div>

    

    <div id="footer" class="page__footer">
      <footer>
        <!-- start custom footer snippets -->

<!-- end custom footer snippets -->
        <div class="page__footer-follow">
  <ul class="social-icons">
    

    

    <li><a href="/hs-abci/feed.xml"><i class="fas fa-fw fa-rss-square" aria-hidden="true"></i> Feed</a></li>
  </ul>
</div>

<div class="page__footer-copyright">&copy; 2020 . Powered by <a href="https://jekyllrb.com" rel="nofollow">Jekyll</a> &amp; <a href="https://mademistakes.com/work/minimal-mistakes-jekyll-theme/" rel="nofollow">Minimal Mistakes</a>.</div>

      </footer>
    </div>

    
  <script src="/hs-abci/assets/js/main.min.js"></script>
  <script src="https://kit.fontawesome.com/4eee35f757.js"></script>










  </body>
</html>
