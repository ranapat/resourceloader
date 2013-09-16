package org.ranapat.resourceloader {
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import org.ranapat.resourceloader.events.ResourceLoaderAllRequiredLoadedEvent;
	import org.ranapat.resourceloader.events.ResourceLoaderBundleCompleteEvent;
	import org.ranapat.resourceloader.events.ResourceLoaderCompleteEvent;
	import org.ranapat.resourceloader.events.ResourceLoaderFailEvent;
	import org.ranapat.resourceloader.events.ResourceLoaderProgressEvent;

	[Event(name = "resourceLoaderFail", type = "org.ranapat.resourceloader.events.ResourceLoaderFailEvent")]
	[Event(name = "resourceLoaderProgress", type = "org.ranapat.resourceloader.events.ResourceLoaderProgressEvent")]
	[Event(name = "resourceLoaderComplete", type = "org.ranapat.resourceloader.events.ResourceLoaderCompleteEvent")]
	[Event(name = "resourceLoaderClassLoaded", type = "org.ranapat.resourceloader.events.ResourceLoaderClassLoadedEvent")]
	[Event(name = "resourceLoaderBundleComplete", type = "org.ranapat.resourceloader.events.ResourceLoaderBundleCompleteEvent")]
	[Event(name = "resourceLoaderAllRequiredLoaded", type = "org.ranapat.resourceloader.events.ResourceLoaderAllRequiredLoadedEvent")]
	final public class ResourceLoader extends EventDispatcher {
		private static var _allowInstance:Boolean;
		private static var _instance:ResourceLoader;
		
		public static function get instance():ResourceLoader {
			if (!ResourceLoader._instance) {
				ResourceLoader._allowInstance = true;
				ResourceLoader._instance = new ResourceLoader();
				ResourceLoader._allowInstance = false;
			}
			return ResourceLoader._instance;
		}
		
		private var uniqueId:uint;

		private var timeoutTimer:Timer;
		private var loader:Loader;
		private var progress:ResourceLoaderProgress;
		private var cache:ResourceLoaderCache;
		private var cacheDispatchQueue:Vector.<ResourceLoaderCacheObject>;
		private var cacheDispatchTimer:Timer;
		private var current:ResourceLoaderQueueObject;
		private var completeBundlesHistory:Dictionary;

		public var autoResetOnEmptyQueue:Boolean = ResourceLoaderSettings.RESOURCE_LOADER_AUTO_RESET_ON_EMPTY_QUEUE;

		public function ResourceLoader() {
			if (ResourceLoader._allowInstance) {
				this.timeoutTimer = new Timer(ResourceLoaderSettings.RESOURCE_LOADER_TIMEOUT_INTERVAL, 1);
				this.timeoutTimer.addEventListener(TimerEvent.TIMER, this.handleTimeoutTimer, false, 0, true);

				this.loader = new Loader();
				this.loader.addEventListener(ProgressEvent.PROGRESS, this.handleLoaderProgress, false, 0, true);
				this.loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, this.handleLoaderProgress, false, 0, true);
				this.loader.addEventListener(Event.COMPLETE, this.handleLoaderComplete, false, 0, true);
				this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.handleLoaderComplete, false, 0, true);
				this.loader.addEventListener(IOErrorEvent.IO_ERROR, this.handleLoaderError, false, 0, true);
				this.loader.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, this.handleLoaderError, false, 0, true);
				this.loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.handleLoaderError, false, 0, true);
				this.loader.contentLoaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, this.handleLoaderError, false, 0, true);

				this.cache = new ResourceLoaderCache();
				this.cacheDispatchQueue = new Vector.<ResourceLoaderCacheObject>();

				this.cacheDispatchTimer = new Timer(ResourceLoaderSettings.RESOURCE_LOADER_CACHE_DISPATCH_TIMER_INTERVAL, 1);
				this.cacheDispatchTimer.addEventListener(TimerEvent.TIMER, this.handleCacheDispatchTimer, false, 0, true);

				this.progress = new ResourceLoaderProgress();
				this.completeBundlesHistory = new Dictionary();
			} else {
				throw new Error("Use ResourceLoader::instance instead.");
			}
		}

		public function destroy():void {
			this.timeoutTimer.removeEventListener(TimerEvent.TIMER, this.handleTimeoutTimer);
			this.timeoutTimer.stop();
			this.timeoutTimer = null;

			this.loader.removeEventListener(ProgressEvent.PROGRESS, this.handleLoaderProgress);
			this.loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, this.handleLoaderProgress);
			this.loader.removeEventListener(Event.COMPLETE, this.handleLoaderComplete);
			this.loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, this.handleLoaderComplete);
			this.loader.removeEventListener(IOErrorEvent.IO_ERROR, handleLoaderError);
			this.loader.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, this.handleLoaderError);
			this.loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, this.handleLoaderError);
			this.loader.contentLoaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, this.handleLoaderError);

			if (this.loader.content) {
				this.loader.unloadAndStop(false);
			} else {
				this.loader.close();
			}
			this.loader = null;

			this.progress = null;

			this.cacheDispatchTimer.removeEventListener(TimerEvent.TIMER, this.handleCacheDispatchTimer);
			this.cacheDispatchTimer.stop();
			this.cacheDispatchTimer = null;
		}

		public function loadASAP(
			url:String,
			size:uint = 1,
			bundle:String = null,
			required:Boolean = false,
			parameters:Vector.<String> = null
		):uint {
			return this.load(url, size, bundle, required, parameters, true);
		}

		public function load(
			url:String,
			size:uint = 1,
			bundle:String = null,
			required:Boolean = false,
			parameters:Vector.<String> = null,
			asap:Boolean = false
		):uint {
			bundle = bundle? bundle : ResourceLoaderConstants.DEFAULT_BUNDLE_NAME;
			if (ResourceLoaderSettings.RESOURCE_LOADER_AUTO_LOAD_ALL_CLASSES && !ResourceLoaderHelper.stringKeyExistsInVector(ResourceLoaderConstants.PARAMETER_LOAD_ALL_CLASSES_FROM_APPLICATION_DOMAIN, parameters)) {
				parameters = parameters == null? new Vector.<String>() : parameters;
				parameters.push(ResourceLoaderConstants.PARAMETER_LOAD_ALL_CLASSES_FROM_APPLICATION_DOMAIN);
			}
			
			if (this.cache.check(url)) {
				var cached:ResourceLoaderCacheObject = this.cache.get(url);
				this.cacheDispatchTimer.reset();
				this.cacheDispatchTimer.start();

				this.cacheDispatchQueue.push(cached);

				return cached.uid;
			} else {
				++this.uniqueId;

				if (asap) {
					this.progress.pushAfterIndex(new ResourceLoaderQueueObject(this.uniqueId, url, size, bundle, required, parameters));
				} else {
					this.progress.push(new ResourceLoaderQueueObject(this.uniqueId, url, size, bundle, required, parameters));
				}
				this.tryLoadNext();

				return this.uniqueId;
			}
		}

		public function isBundleComplete(bundle:String):Boolean {
			return this.completeBundlesHistory[bundle];
		}

		public function getBundleProgress(bundle:String):Number {
			return this.progress.getProgress(bundle);
		}

		public function getParameters(uid:uint):Vector.<String> {
			return this.progress.getParameters(uid);
		}

		private function tryLoadNext():void {
			if (!this.timeoutTimer.running) {
				this.loadNext();
			}
		}

		private function loadNext():void {
			var tmp:ResourceLoaderQueueObject = this.progress.next;
			if (tmp) {
				tmp.status = ResourceLoaderConstants.LOADING;
				this.completeBundlesHistory[tmp.bundle] = false;

				this.timeoutTimer.reset();
				this.timeoutTimer.start();

				this.loader.load(
					new URLRequest(tmp.url),
					new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain))
				);

				this.current = tmp;
			} else {
				this.current = null;

				if (this.autoResetOnEmptyQueue) {
					this.progress.reset();
				}
			}
		}

		private function handleMassSignalDispatch(_currentBundle:String, _currentRequired:Boolean):void {
			if (_currentRequired && this.progress.haveRequired(_currentBundle) && !this.progress.isRequiredPending(_currentBundle)) {
				this.dispatchEvent(new ResourceLoaderAllRequiredLoadedEvent(_currentBundle));
			}
			if (this.progress.isBundleNotInProgress(_currentBundle)) {
				this.completeBundlesHistory[_currentBundle] = true;
				this.dispatchEvent(new ResourceLoaderBundleCompleteEvent(_currentBundle));
			}
		}

		private function handleTimeoutTimer(e:TimerEvent):void {
			var _currentUid:uint = this.current.uid;
			var _currentBundle:String = this.current.bundle;
			var _currentRequired:Boolean = this.current.required;
			var _currentRetries:uint = this.current.timeoutRetries;

			this.current.status = ResourceLoaderConstants.TIMEOUT;
			this.cache.remove(this.current.url);
			if (_currentRetries < ResourceLoaderSettings.RESOURCE_LOADER_TIMEOUT_AUTO_RETRIES) {
				++this.current.timeoutRetries;
				this.current.status = ResourceLoaderConstants.PENDING;
				this.progress.push(this.current);
			}
			this.current = null;

			this.dispatchEvent(new ResourceLoaderFailEvent(_currentUid, ResourceLoaderConstants.FAIL_REASON_TIMEOUT));
			this.handleMassSignalDispatch(_currentBundle, _currentRequired);

			this.tryLoadNext();
		}

		private function handleCacheDispatchTimer(e:TimerEvent):void {
			var _copy:Vector.<ResourceLoaderCacheObject> = new Vector.<ResourceLoaderCacheObject>();
			while (this.cacheDispatchQueue.length > 0) {
				_copy.push(this.cacheDispatchQueue.shift());
			}
			while (_copy.length > 0) {
				var tmp:ResourceLoaderCacheObject = _copy.shift();
				this.dispatchEvent(new ResourceLoaderCompleteEvent(tmp.uid, tmp.target, tmp.applicationDomain));
			}
		}

		private function handleLoaderProgress(e:ProgressEvent):void {
			this.current.bytesTotal = e.bytesTotal;
			this.current.bytesLoaded = e.bytesLoaded;

			this.dispatchEvent(new ResourceLoaderProgressEvent(current.uid, progress.getProgress(current.bundle), current.bundle));
		}

		private function handleLoaderComplete(e:Event):void {
			var _currentUid:uint = this.current.uid;
			var _currentBundle:String = this.current.bundle;
			var _currentRequired:Boolean = this.current.required;
			var _currentParameters:Vector.<String> = this.current.parameters;

			this.cache.add(this.current.url, new ResourceLoaderCacheObject(
					_currentUid,
					e.target,
					e.target.applicationDomain
			));

			this.current.status = ResourceLoaderConstants.COMPLETE;
			this.current = null;

			this.dispatchEvent(new ResourceLoaderCompleteEvent(_currentUid, e.target, e.target.applicationDomain));
			this.handleMassSignalDispatch(_currentBundle, _currentRequired);
			if (ResourceLoaderHelper.stringKeyExistsInVector(ResourceLoaderConstants.PARAMETER_LOAD_ALL_CLASSES_FROM_APPLICATION_DOMAIN, _currentParameters)) {
				ResourceClasses.instance.addAllClassesFromApplicationDomain(e.target.applicationDomain, e.target);
			}

			this.timeoutTimer.stop();
			this.tryLoadNext();
		}

		private function handleLoaderError(e:IOErrorEvent):void {
			var _currentUid:uint = this.current.uid;
			var _currentBundle:String = this.current.bundle;
			var _currentRequired:Boolean = this.current.required;
			var _currentRetries:uint = this.current.generalRetries;

			this.current.status = ResourceLoaderConstants.ERROR;
			this.cache.remove(this.current.url);
			if (_currentRetries < ResourceLoaderSettings.RESOURCE_LOADER_GENERAL_AUTO_RETRIES) {
				++this.current.generalRetries;
				this.current.status = ResourceLoaderConstants.PENDING;
				this.progress.push(this.current);
			}
			this.current = null;

			this.dispatchEvent(new ResourceLoaderFailEvent(_currentUid, e.toString()));
			this.handleMassSignalDispatch(_currentBundle, _currentRequired);

			this.timeoutTimer.stop();
			this.tryLoadNext();
		}
	}
}
