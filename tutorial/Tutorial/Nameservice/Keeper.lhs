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
<meta property="og:url" content="/hs-abci/tutorial/Tutorial/Nameservice/Keeper.lhs">













<link rel="canonical" href="/hs-abci/tutorial/Tutorial/Nameservice/Keeper.lhs">




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
    
    # Keeper

## Definition

"Keeper" is a word taken from the cosmos-sdk, it's basically the interface that the module exposes to the other modules in the application. For example, in the Nameservice app, the Nameservice keeper exposes functions to `buy`/`sell`/`delete` entries in the mapping. Likewise, the Nameservice keeper depends on the keeper from the `bank` module in order to transfer tokens when executing those methods. A keeper might also indicate what kinds of exceptions are able to be caught and thrown from the module. For example, calling `transfer` while buying a `Name` might throw an `InsufficientFunds` exception, which the Namerservice module can chose whether to catch or not.

## Tutorial.Nameservice.Keeper

```haskell
{-# LANGUAGE TemplateHaskell #-}
module Tutorial.Nameservice.Keeper where

import Data.Proxy
import Data.String.Conversions (cs)
import GHC.TypeLits (symbolVal)
import Polysemy (Sem, Members, makeSem, interpret)
import Polysemy.Error (Error, throw, mapError)
import Polysemy.Output (Output)
import Nameservice.Modules.Nameservice.Messages (DeleteName(..))
import Nameservice.Modules.Nameservice.Types (Whois(..), Name, NameDeleted(..), NameserviceModuleName, NameserviceError(..))
import Nameservice.Modules.Token (Token, mint)
import qualified Tendermint.SDK.BaseApp as BA
```

Generally a keeper is defined by a set of effects that the module introduces and depends on. In the case of Nameservice, we introduce the custom `Nameservice` effect:


```haskell
data NameserviceKeeper m a where
  PutWhois :: Name -> Whois -> NameserviceKeeper m ()
  GetWhois :: Name -> NameserviceKeeper m (Maybe Whois)
  DeleteWhois :: Name -> NameserviceKeeper m ()

makeSem ''NameserviceKeeper

type NameserviceEffs = '[NameserviceKeeper, Error NameserviceError]
```

where `makeSem` is from polysemy, it uses template Haskell to create the helper functions `putWhoIs`, `getWhois`, `deleteWhois`:

```haskell
putWhois :: forall r. Member NameserviceKeeper r => Name -> Whois -> Sem r ()
getWhois :: forall r. Member NameserviceKeeper r => Name -> Sem r (Maybe Whois)
deleteWhois :: forall r. Member NameserviceKeeper r => Name -> Sem r ()
```

We can then write the top level function for example for deleting a name:

```haskell
deleteName
  :: Members [Token, Output BA.Event] r
  => Members [NameserviceKeeper, Error NameserviceError] r
  => DeleteName
  -> Sem r ()
deleteName DeleteName{..} = do
  mWhois <- getWhois deleteNameName
  case mWhois of
    Nothing -> throw $ InvalidDelete "Can't remove unassigned name."
    Just Whois{..} ->
      if whoisOwner /= deleteNameOwner
        then throw $ InvalidDelete "Deleter must be the owner."
        else do
          mint deleteNameOwner whoisPrice
          deleteWhois deleteNameName
          BA.emit NameDeleted
            { nameDeletedName = deleteNameName
            }
```

The control flow should be pretty clear:
1. Check that the name is actually registered, if not throw an error.
2. Check that the name is registered to the person trying to delete it, if not throw an error.
3. Refund the tokens locked in the name to the owner.
4. Delete the entry from the database.
5. Emit an event that the name has been deleted.

Taking a look at the class constraints, we see

```haskell
(Members NameserviceEffs, Members [Token, Output Event] r)
```

- The `NameserviceKeeper` effect is required because the function may manipulate the modules database with `deleteName`.
- The `Error NameserviceError` effect is required because the function may throw an error.
- The `Token` effect is required because the function will mint coins.
- The `Output Event` effect is required because the function may emit a `NameDeleted` event.

### Evaluating Module Effects

Like we said before, all modules must ultimately compile to the set of effects belonging to `BaseApp`. For effects interpreted to `RawStore`, this means that you will need to define something called a `StoreKey`.


A `StoreKey` is effectively a namespacing inside the database, and is unique for a given module. In theory it could be any `ByteString`, but the natural definition in the case of Nameservice is would be something like

```haskell
storeKey :: BA.StoreKey NameserviceModuleName
storeKey = BA.StoreKey . cs . symbolVal $ (Proxy @NameserviceModuleName)
```

With this `storeKey` it is possible to write the `eval` function to resolve the effects defined in Nameservice, namely the `NameserviceKeeper` effect and `Error NameserviceError`:

```haskell
eval
  :: Members [BA.RawStore, Error BA.AppError] r
  => forall a. Sem (NameserviceKeeper ': Error NameserviceError ': r) a
  -> Sem r a
eval = mapError BA.makeAppError . evalNameservice
  where
    evalNameservice
      :: Members [BA.RawStore, Error BA.AppError] r
      => Sem (NameserviceKeeper ': r) a -> Sem r a
    evalNameservice =
      interpret (\case
          GetWhois name -> BA.get storeKey name
          PutWhois name whois -> BA.put storeKey name whois
          DeleteWhois name -> BA.delete storeKey name
        )
```

[Next: Query](Query.md)


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
