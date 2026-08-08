{{flutter_js}}
{{flutter_build_config}}

const searchParams = new URLSearchParams(window.location.search);
const forceCanvaskit = searchParams.get('force_canvaskit') === 'true';
const userConfig = forceCanvaskit ? {'renderer': 'canvaskit'} : {};
const progressBar = document.querySelector('#progress-bar');
const progressIndicator = document.querySelector('#progress-indicator');

const additionalScripts = [
    // Add additional scripts here.
];

function injectScript(url) {
    return new Promise(function (resolve) {
    let scriptTag = document.createElement('script');
    scriptTag.src = url;
    scriptTag.type = 'application/javascript';
    scriptTag.onload = function () {
        resolve();
    };

    document.body.append(scriptTag);
    });
}

function beginPreloading(manifestAssets) {
    var assets = [
    'flutter.js',
    'main.dart.js',
    'canvaskit/canvaskit.wasm',
    'canvaskit/canvaskit.js',
    ...additionalScripts,
    ...manifestAssets,
    ];
    let totalAssets = assets.length + 1;
    let loaded = 0;

    const batchSize = 40;

    async function reportProgress() {
        loaded++;
        const value = Math.floor((loaded / totalAssets) * 100) + '%';
        progressIndicator.style.width = value;

        if (assets.length == 0) {
            dispatchAppLoad();
        } else {
            load(assets.shift());
        }
    }

    function load(url) {
        const req = new XMLHttpRequest();
        req.onload = reportProgress;
        req.open('get', url);
        req.send();
    }

    function startBatch() {
        const end = Math.min(batchSize, assets.length);
        for (let i = 0; i < end; i++) {
            load(assets.shift());
        }
    }


    var scriptLoaded = false;
    async function dispatchAppLoad() {
        if (scriptLoaded) {
            return;
        }
        scriptLoaded = true;

        for (let i = 0; i < additionalScripts.length; i++) {
            await injectScript(additionalScripts[i]);
        }

        await injectScript('flutter.js');
        
        // Download main.dart.js
        _flutter.loader.load({
            config: userConfig,
            entrypointUrl: "/main.dart.js",
            serviceWorkerSettings: {
                serviceWorkerVersion: {{flutter_service_worker_version}},
                serviceWorkerUrl: "/flutter_service_worker.js?v=",
            },
            onEntrypointLoaded: function (engineInitializer) {
                if ('serviceWorker' in navigator) {
                    navigator.serviceWorker.register('firebase-messaging-sw.js', {
                        scope: '/firebase-cloud-messaging-push-scope',
                    }).then((registration) => {
                        console.log('Service Worker registered with scope:', registration);
                    }).catch((e) => {
                        console.error("Error", e)
                    });
                }
                engineInitializer.initializeEngine().then(async function (appRunner) {
                    window.addEventListener("flutter-first-frame", function () {
                        progressBar.remove();
                        document.body.classList.remove('loading-mode');
                    });

                    appRunner.runApp();
                });
            }
        });
    }

    startBatch();
}

window.addEventListener('load', async function (ev) {
    const response = await fetch('assets/AssetManifest.json');
    const manifest = await response.json();
    const assets = Object.values(manifest)
    .map((list) => list.map((url) => 'assets/' + url))
    .reduce((arr, curr) => [...arr, ...curr], []);

    beginPreloading(assets);
});
