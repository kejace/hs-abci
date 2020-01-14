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
<meta property="og:url" content="/hs-abci/tutorial/Tutorial/Nameservice/Module.lhs">













<link rel="canonical" href="/hs-abci/tutorial/Tutorial/Nameservice/Module.lhs">




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
    
    # Module

## Tutorial.Nameservice.Module

At this point we can collect the relevant pieces to form the Nameservice module:

```haskell
module Tutorial.Nameservice.Module where

import Nameservice.Modules.Nameservice.Keeper (NameserviceEffs, eval)
import Nameservice.Modules.Nameservice.Messages (NameserviceMessage)
import Nameservice.Modules.Nameservice.Query (Api, server)
import Nameservice.Modules.Nameservice.Router (router)
import Nameservice.Modules.Nameservice.Types (NameserviceModuleName)
import Nameservice.Modules.Token                (TokenEffs)
import Polysemy                                 (Members)
import Tendermint.SDK.Application               (Module (..),
                                                 defaultTxChecker)
import Tendermint.SDK.BaseApp                   (BaseAppEffs)

-- a convenient type alias
type NameserviceM r =
  Module NameserviceModuleName NameserviceMessage () Api NameserviceEffs r

nameserviceModule
  :: Members BaseAppEffs r
  => Members TokenEffs r
  => Members NameserviceEffs r
  => NameserviceM r
nameserviceModule = Module
  { moduleTxDeliverer = router
  , moduleTxChecker = defaultTxChecker
  , moduleQueryServer = server
  , moduleEval = eval
  }
```

We are using `defaultTxChecker` as our transaction checker, which is a static message validator defined as 

```haskell
defaultTxChecker
  :: Member (Error AppError) r
  => ValidateMessage msg
  => RoutedTx msg
  -> Sem r ()
defaultTxChecker (RoutedTx Tx{txMsg}) =
  case validateMessage txMsg of
    V.Failure err ->
      throwSDKError . MessageValidation . map formatMessageSemanticError $ err
    V.Success _ -> pure ()
```

This means that we are only doing static validation, meaning that we're not interested in checking message validitity against the database. This is reflected in the return type for the checker `Sem r ()`. If you want to add custom checking, you may write a custom checker for your module. 

Note the constraints on the module's effects `r`:

```haskell
...
  :: Members BaseAppEffs r
  => Members TokenEffs r
  => Members NameserviceEffs r
...
```

This is saying that we can run this module in any context for which `r` has the effects from `BaseApp`, `Token`, and `Nameservice`. This is how we explicitly declare module dependencies, by using the constraint system.

Other than that, there is nothing really to note. We are just collecting the pieces we have already defined in one place.

[Next: Application](Application.md)


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
