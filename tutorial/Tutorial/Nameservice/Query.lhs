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
<meta property="og:url" content="/hs-abci/tutorial/Tutorial/Nameservice/Query.lhs">













<link rel="canonical" href="/hs-abci/tutorial/Tutorial/Nameservice/Query.lhs">




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
    
    # Query

## Tutorial.Nameservice.Query

```haskell
module Tutorial.Nameservice.Query where

import Data.Proxy
import Nameservice.Modules.Nameservice.Keeper (storeKey)
import Nameservice.Modules.Nameservice.Types (Whois, Name)
import Polysemy (Sem, Members)
import Polysemy.Error (Error)
import Tendermint.SDK.BaseApp (RawStore, AppError, RouteT, QueryApi, storeQueryHandlers)
```

The way to query application state is via the `query` message which uses a `url` like format. The SDK tries to abstract as much of this away as possible. For example, if you want to only serve state that you have registered with the store via the `IsKey` class, then things are very easy. If you need to make joins to serve requests, we support this as well and it's not hard, but we will skip this for now.

In the case we just want to serve data we have registered with the `IsKey` class, we simply need to declare some types

```haskell
type NameserviceContents = '[(Name, Whois)]

type Api = QueryApi NameserviceContents
```

- `NameserviceContents` is simply a type level list of the key value pairs you wish to serve. In this case there is only `Name -> Whois`
- `Api` is the list of leaves of valid url's for this module. When the type family `QueryApi` is applied, it will construct the leaves from the key value pairs based on the `IsKey` class. In this case you end up with only `"/whois"` endpoint, which accepts the `Name` in the `data` field of the `query` message encoded via the `HasCodec` class.

To serve all the data registered with the `IsKey` class, we can use the `storeQueryHandlers` function, supplying a proxy for the store contents, the `storeKey` and a proxy for the effects used in serving requests. In this case because we are serving only types registered with the store, we will need to assume the `RawStore` and `Error AppError` effects.

```haskell
server
  :: Members [RawStore, Error AppError] r
  => RouteT Api (Sem r)
server =
  storeQueryHandlers (Proxy @NameserviceContents) storeKey (Proxy :: Proxy (Sem r))
```

Here `RouteT` is a type family that can build a server from the `Api` type to handle incoming requests. It is similar to how `servant` works, and is largely copy-pasted from that codebase.

[Next: Module](Module.md)


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
