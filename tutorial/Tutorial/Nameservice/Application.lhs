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
<meta property="og:url" content="/hs-abci/tutorial/Tutorial/Nameservice/Application.lhs">













<link rel="canonical" href="/hs-abci/tutorial/Tutorial/Nameservice/Application.lhs">




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
    
    # Application

## From Modules to App

The `App` type in `Network.ABCI.Server` is defined as 

```haskell
newtype App m = App
  { unApp :: forall (t :: MessageType). Request t -> m (Response t) }
```

and ultimately our configuration of modules must be converted to this format. This is probably the most important part of the SDK, to provide the bridge between the list of modules - a heterogeneous list of type `Modules` - and the actual application. The type that provides the input for this bridge is `HandlersContext`:

```haskell
data HandlersContext alg ms r core = HandlersContext
  { signatureAlgP :: Proxy alg
  , modules       :: M.Modules ms r
  , compileToCore :: forall a. ScopedEff core a -> Sem core a
  }
```

where
- `alg` is the signature schema you would like to use for authentication (e.g. Secp256k1)
- `ms` is the type level list of modules
- `r` is the global effects list for the application
- `core` is the set of core effects that are used to interpet `BaseApp` to `IO`.

We should say a few words on this `compileToCore` field. The application developer has access to any effects in `BaseApp`, 
but `BaseApp` itself still needs to be interpreted in order to run the application. In other words, `BaseApp` is still just a 
list of free effects. The set of effects capable of interpreting `BaseApp` is called `core`, and while the developer is free to provide any `core` they want, we have a standard set of them in the SDK - e.g. in memory, production, etc. 

The `ScopedEff` type is more complicated and not relevant to the discussion of application development. Long story short, tendermint core requests three connections to the application's state - `Consensus`, `Mempool` and `Query`. The `ScopedEff` type is used to abstract this concern away from the developer, and as long as you are using one of the `core` effects provided in the SDK you don't need to worry about it.

## Tutorial.Nameservice.Application

```haskell
module Tutorial.Nameservice.Application where

import Data.Proxy
import Nameservice.Modules.Nameservice (nameserviceModule, NameserviceM, NameserviceEffs)
import Nameservice.Modules.Token (tokenModule, TokenM, TokenEffs)
import Network.ABCI.Server.App (App)
import Polysemy (Sem)
import Tendermint.SDK.Modules.Auth (authModule, AuthEffs, AuthM)
import Tendermint.SDK.Application (Modules(..), HandlersContext(..), baseAppAnteHandler, makeApp)
import Tendermint.SDK.BaseApp (BaseApp, CoreEffs, (:&), compileScopedEff)
import Tendermint.SDK.Crypto (Secp256k1)
```

This is the part of the application where the effects list must be given a monomorphic type. There is also a requirement
that the `Modules` type for the application be given the same _order_ as the effects introducted. This ordering problem is due
to the fact that type level lists are used to represent the effects in `polysemy`, and the order matters there. Still, it's only a small annoyance.


```haskell
type EffR =
   NameserviceEffs :&
   TokenEffs :&
   AuthEffs :&
   BaseApp CoreEffs

type NameserviceModules =
   '[ NameserviceM EffR
    , TokenM EffR
    , AuthM EffR
    ]
```

Notice that we've specified `EffR` as the effects list for each of the modules to run in, which trivially satisfies the constraints on each module at the definition site, since it is simply the union of all effects.

We're now ready to define the `HandlersContext` for our application:

```haskell
handlersContext :: HandlersContext Secp256k1 NameserviceModules EffR CoreEffs
handlersContext = HandlersContext
  { signatureAlgP = Proxy @Secp256k1
  , modules = nameserviceModules
  , compileToCore  = compileScopedEff
  , anteHandler = baseAppAnteHandler
  }
  where
  nameserviceModules :: Modules NameserviceModules EffR
  nameserviceModules =
       nameserviceModule
    :+ tokenModule
    :+ authModule
    :+ NilModules
```

Finally we're able to define our application that runs in the `CoreEffs` context defined in the SDK:


```haskell
app :: App (Sem CoreEffs)
app = makeApp handlersContext 
```


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
