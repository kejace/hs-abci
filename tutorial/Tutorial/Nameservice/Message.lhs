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
<meta property="og:url" content="/hs-abci/tutorial/Tutorial/Nameservice/Message.lhs">













<link rel="canonical" href="/hs-abci/tutorial/Tutorial/Nameservice/Message.lhs">




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
    
    # Message

## Message Types

The `Message` module is ultimately a small state machine used for processing messages. Each module must define what messages it accepts, if any. Like many other types found in the SDK, this message class must implement the `HasCodec` class. We recommend using a protobuf serialization format for messages using either the `proto3-suite` or `proto-lens` libraries, though in theory you could use anything (e.g. `JSON`).

### `proto3-suite`
The advantages of using the `proto3-suite` library are that it has support for generics and that you can generate a `.proto` file from your haskell code for export to other applications. This is particularly useful when prototyping or when you have control over the message specification. 
The disadvantage is that `proto3-suite` doesn't act as a `protoc` plugin, and instead uses it's own protobuf parser. This means that you do not have access to the full protobuf specs when parsing `.proto` files.

### `proto-lens`
The advantages of using `proto-lens` are that it can parse and generate types for pretty much any `.proto` file. 
The disadvantage is that the generated code is a bit strange, and may require you to create wrapper types to avoid depending directly on the generated code. An additional disadvantage is that you cannot generate `.proto` files from haskell code.

All in all, neither is really difficult to work with, and depending on what stage you're at in development you might chose one over the other.

## Tutorial.Nameservice.Message

```haskell
module Tutorial.Nameservice.Message where

import Data.Bifunctor (first)
import Data.Foldable (sequenceA_)
import Data.String.Conversions (cs)
import Data.Text (Text)
import GHC.Generics (Generic)
import Nameservice.Modules.Nameservice.Types (Name(..))
import Nameservice.Modules.Token (Amount)
import Nameservice.Modules.TypedMessage (TypedMessage(..))
import Proto3.Suite (Named, Message, fromByteString, toLazyByteString)
import Tendermint.SDK.Types.Address (Address)
import Tendermint.SDK.Types.Message (Msg(..), ValidateMessage(..),
                                     isAuthorCheck, nonEmptyCheck,
                                     coerceProto3Error, formatMessageParseError)
import Tendermint.SDK.Codec (HasCodec(..))
```

### Message Definitions

For the puroposes of the tutorial, we will use the `proto3-suite` for the message codecs:


```haskell
data SetName = SetName
  { setNameName  :: Name
  , setNameOwner :: Address
  , setNameValue :: Text
  } deriving (Eq, Show, Generic)

instance Message SetName
instance Named SetName

instance HasCodec SetName where
  encode = cs . toLazyByteString
  decode = first (formatMessageParseError . coerceProto3Error) . fromByteString

data DeleteName = DeleteName
  { deleteNameOwner :: Address
  , deleteNameName  :: Name
  } deriving (Eq, Show, Generic)

instance Message DeleteName
instance Named DeleteName

instance HasCodec DeleteName where
  encode = cs . toLazyByteString
  decode = first (formatMessageParseError . coerceProto3Error) . fromByteString

data BuyName = BuyName
  { buyNameBid   :: Amount
  , buyNameName  :: Name
  , buyNameValue :: Text
  , buyNameBuyer :: Address
  } deriving (Eq, Show, Generic)

instance Message BuyName
instance Named BuyName

instance HasCodec BuyName where
  encode = cs . toLazyByteString
  decode = first (formatMessageParseError . coerceProto3Error) . fromByteString
```

We want a sum type that covers all possible messages the module can receive. As `protobuf` is a schemaless format, parsing is sometimes ambiguous if two types are the same up to field names, or one is a subset of the other. For this reason we defined a type called `TypedMessage`:

```haskell
data TypedMessage = TypedMessage
  { typedMessageType     :: Text
  , typedMessageContents :: BS.ByteString
  } deriving (Eq, Show, Generic)

instance Message TypedMessage
instance Named TypedMessage

instance HasCodec TypedMessage where
  encode = cs . toLazyByteString
  decode = first (formatMessageParseError . coerceProto3Error) . fromByteString
```

This allows us to disambiguated messages based on the `type` field, so that for example we can distinguish `DeleteName` from a submessage of `BuyName`. With that out of the way, we can define the module level (sum) message type:

```haskell
data NameserviceMessage =
    NSetName SetName
  | NBuyName BuyName
  | NDeleteName DeleteName
  deriving (Eq, Show, Generic)

instance HasCodec NameserviceMessage where
  decode bs = do
    TypedMessage{..} <- decode bs
    case typedMessageType of
      "SetName" -> NSetName <$> decode typedMessageContents
      "DeleteName" -> NDeleteName <$> decode typedMessageContents
      "BuyName" -> NBuyName <$> decode typedMessageContents
      _ -> Left . cs $ "Unknown Nameservice message type " ++ cs typedMessageType
  encode = \case
    NSetName msg -> encode msg
    NBuyName msg -> encode msg
    NDeleteName msg -> encode msg
```

## Message Validation

Message validation is an important part of the transaction life cycle. When a `checkTx` message comes in, Tendermint is asking whether a transaction bytestring from the mempool is potentially runnable. At the very least this means that 

1. The transaction parses to a known message
2. The message passes basic signature authentication, if any is required.
3. The message author has enough funds for the gas costs, if any.
4. The message can be successfully routed to a module without handling.

On top of this you might wish to ensure other static properties of the message, such as that the author of the message is the owner of the funds being transfered. For this we have a `ValidateMessage` class:

```haskell
data MessageSemanticError =
    PermissionError Text
  | InvalidFieldError Text
  | OtherSemanticError Text

class ValidateMessage msg where
  validateMessage :: Msg msg -> Validation [MessageSemanticError] ()
```

We're using the applicative functor [`Data.Validation.Validation`](https://hackage.haskell.org/package/validation-1.1/docs/Data-Validation.html#t:Validation) to perform valdiation because it is capable of reporting all errors at once, rather than the first that occurs as in ther case with something like `Either`.

Here's what the `isAuthor` check looks like, that was described above:

```haskell
isAuthorCheck
  :: Text
  -> Msg msg
  -> (msg -> Address)
  -> V.Validation [MessageSemanticError] ()
isAuthorCheck fieldName Msg{msgAuthor, msgData} getAuthor
  | getAuthor msgData /= msgAuthor = 
      _Failure # [PermissionError $ fieldName <> " must be message author."]
  | otherwise = Success ()
```

It is also possible to run dynamic checks on the transaction, i.e. checks that need to query state in order to succeed or fail. We will say more on this later.

Here are the validation instances for our message types, which use some of the combinators defined in the SDK 

```haskell
instance ValidateMessage SetName where
  validateMessage msg@Msg{..} =
    let SetName{setNameName, setNameValue} = msgData
        Name name = setNameName
    in sequenceA_
        [ nonEmptyCheck "Name" name
        , nonEmptyCheck "Value" setNameValue
        , isAuthorCheck "Owner" msg setNameOwner
        ]

instance ValidateMessage DeleteName where
  validateMessage msg@Msg{..} =
    let DeleteName{deleteNameName} = msgData
        Name name = deleteNameName
    in sequenceA_
       [ nonEmptyCheck "Name" name
       , isAuthorCheck "Owner" msg deleteNameOwner
       ]

instance ValidateMessage BuyName where
  validateMessage msg@Msg{..} =
    let BuyName{buyNameName, buyNameValue} = msgData
        Name name = buyNameName
    in sequenceA_
        [ nonEmptyCheck "Name" name
        , nonEmptyCheck "Value" buyNameValue
        , isAuthorCheck "Owner" msg buyNameBuyer
        ]
```

Finally we can define a `ValidateMessage` instance for our top level message type by dispatching on the message type:

```haskell
instance ValidateMessage NameserviceMessage where
  validateMessage m@Msg{msgData} = case msgData of
    NBuyName msg    -> validateMessage m {msgData = msg}
    NSetName msg    -> validateMessage m {msgData = msg}
    NDeleteName msg -> validateMessage m {msgData = msg}
```

[Next: Keeper](Keeper.md)


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
