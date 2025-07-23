import { registerApplication, start } from 'single-spa';

registerApplication({
  name: '@reactmf/product-list',
  app: () => System.import('@reactmf/product-list'),
  activeWhen: () => true,
  customProps: {
    domElement: document.getElementById('product-list-mfe'),
  }
});

registerApplication({
  name: '@reactmf/user-profile', 
  app: () => System.import('@reactmf/user-profile'),
  activeWhen: () => true,
  customProps: {
    domElement: document.getElementById('user-profile-mfe'),
  }
});

start({
  urlRerouteOnly: true,
});
