package org.ranapat.resourceloader {
	import flash.display.Loader;
	import flash.display.LoaderInfo;
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

		private var parallels:ResourceLoaderParallels;
		private var progress:ResourceLoaderProgress;
		private var cache:ResourceLoaderCache;
		private var cacheDispatchQueue:Vector.<ResourceLoaderCacheObject>;
		private var cacheDispatchTimer:Timer;
		private var completeBundlesHistory:Dictionary;

		public var autoResetOnEmptyQueue:Boolean = ResourceLoaderSettings.RESOURCE_LOADER_AUTO_RESET_ON_EMPTY_QUEUE;

		public function ResourceLoader() {
			if (ResourceLoader._allowInstance) {
				this.parallels = new ResourceLoaderParallels();
				var tmp:ResourceLoaderParallelsObject;
				var timer:Timer;
				var loader:Loader;
				var length:uint = this.parallels.length;
				for (var i:uint = 0; i < length; ++i) {
					tmp = this.parallels.get(i);
					
					timer = tmp.timer;
					timer.addEventListener(TimerEvent.TIMER, this.handleTimeoutTimer, false, 0, true);
					
					loader = tmp.loader;
					loader.addEventListener(ProgressEvent.PROGRESS, this.handleLoaderProgress, false, 0, true);
					loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, this.handleLoaderProgress, false, 0, true);
					loader.addEventListener(Event.COMPLETE, this.handleLoaderComplete, false, 0, true);
					loader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.handleLoaderComplete, false, 0, true);
					loader.addEventListener(IOErrorEvent.IO_ERROR, this.handleLoaderError, false, 0, true);
					loader.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, this.handleLoaderError, false, 0, true);
					loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.handleLoaderError, false, 0, true);
					loader.contentLoaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, this.handleLoaderError, false, 0, true);
				}

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
			var tmp:ResourceLoaderParallelsObject;
			var timer:Timer;
			var loader:Loader;
			var length:uint = this.parallels.length;
			for (var i:uint = 0; i < length; ++i) {
				tmp = this.parallels.get(i);
				
				timer = tmp.timer;
				timer.removeEventListener(TimerEvent.TIMER, this.handleTimeoutTimer);
				timer.stop();
				timer = null;
				tmp.timer = null;
				
				loader = tmp.loader;
				loader.removeEventListener(ProgressEvent.PROGRESS, this.handleLoaderProgress);
				loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, this.handleLoaderProgress);
				loader.removeEventListener(Event.COMPLETE, this.handleLoaderComplete);
				loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, this.handleLoaderComplete);
				loader.removeEventListener(IOErrorEvent.IO_ERROR, handleLoaderError);
				loader.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, this.handleLoaderError);
				loader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, this.handleLoaderError);
				loader.contentLoaderInfo.uncaughtErrorEvents.removeEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, this.handleLoaderError);
				if (loader.content) {
					loader.unloadAndStop(false);
				} else {
					loader.close();
				}
				loader = null;
				tmp.loader = null;
				
				tmp.current = null;
			}
			this.parallels = null;

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
		
		public function markBundleNotComplete(bundle:String):void {
			this.completeBundlesHistory[bundle] = false;
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
			if (this.parallels.anyFree) {
				this.loadNext();
			}
		}

		private function loadNext():void {
			var tmp:ResourceLoaderQueueObject = this.progress.next;
			if (tmp) {
				tmp.status = ResourceLoaderConstants.LOADING;
				this.completeBundlesHistory[tmp.bundle] = false;
				
				var free:ResourceLoaderParallelsObject = this.parallels.free;
				var timer:Timer = free.timer;
				var loader:Loader = free.loader;

				timer.reset();
				timer.start();

				loader.load(
					new URLRequest(tmp.url),
					new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain))
				);

				free.current = tmp;
			}
		}
		
		private function tryAutoReset():void {
			if (!this.progress.anyBundleInProgress() && this.autoResetOnEmptyQueue) {
				this.progress.reset();
			}
		}

		private function handleMassEventDispatch(_currentBundle:String, _currentRequired:Boolean):void {
			if (_currentRequired && this.progress.haveRequired(_currentBundle) && !this.progress.isRequiredPending(_currentBundle)) {
				this.dispatchEvent(new ResourceLoaderAllRequiredLoadedEvent(_currentBundle));
			}
			if (this.progress.isBundleNotInProgress(_currentBundle)) {
				this.completeBundlesHistory[_currentBundle] = true;
				this.dispatchEvent(new ResourceLoaderBundleCompleteEvent(_currentBundle));
			}
		}

		private function handleTimeoutTimer(e:TimerEvent):void {
			var current:ResourceLoaderQueueObject = this.parallels.currentByTimer(e.target as Timer);
			if (current) {
				var _currentUid:uint = current.uid;
				var _currentBundle:String = current.bundle;
				var _currentRequired:Boolean = current.required;
				var _currentRetries:uint = current.timeoutRetries;

				current.status = ResourceLoaderConstants.TIMEOUT;
				this.cache.remove(current.url);
				if (_currentRetries < ResourceLoaderSettings.RESOURCE_LOADER_TIMEOUT_AUTO_RETRIES) {
					++current.timeoutRetries;
					current.status = ResourceLoaderConstants.PENDING;
					this.progress.push(current);
				}
				
				this.parallels.unsetCurrent(current);
				
				this.dispatchEvent(new ResourceLoaderFailEvent(_currentUid, ResourceLoaderConstants.FAIL_REASON_TIMEOUT));
				this.tryAutoReset();
			}
			
			var loader:Loader = this.parallels.loaderByTimer(e.target as Timer);
			if (loader) {
				try { loader.close(); } catch (e:Error) { /**/ }
			}

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
			var current:ResourceLoaderQueueObject = this.parallels.currentByLoader((e.target as LoaderInfo).loader);
			if (current) {
				current.bytesTotal = e.bytesTotal;
				current.bytesLoaded = e.bytesLoaded;
				
				this.dispatchEvent(new ResourceLoaderProgressEvent(current.uid, progress.getProgress(current.bundle), current.bundle));
			}
			
			var timer:Timer = this.parallels.timerByLoader((e.target as LoaderInfo).loader);
			if (timer) {
				timer.reset();
				timer.start();
			}
		}

		private function handleLoaderComplete(e:Event):void {
			var current:ResourceLoaderQueueObject = this.parallels.currentByLoader((e.target as LoaderInfo).loader);
			if (current) {
				var _currentUid:uint = current.uid;
				var _currentBundle:String = current.bundle;
				var _currentRequired:Boolean = current.required;
				var _currentParameters:Vector.<String> = current.parameters;

				this.cache.add(current.url, new ResourceLoaderCacheObject(
						_currentUid,
						e.target,
						e.target.applicationDomain
				));

				current.status = ResourceLoaderConstants.COMPLETE;
				
				this.parallels.unsetCurrent(current);
				
				if (ResourceLoaderHelper.stringKeyExistsInVector(ResourceLoaderConstants.PARAMETER_LOAD_ALL_CLASSES_FROM_APPLICATION_DOMAIN, _currentParameters)) {
					ResourceClasses.instance.addAllClassesFromApplicationDomain(e.target.applicationDomain, e.target);
				}
				this.dispatchEvent(new ResourceLoaderCompleteEvent(_currentUid, e.target, e.target.applicationDomain));
				this.handleMassEventDispatch(_currentBundle, _currentRequired);
				this.tryAutoReset();
			}

			var timer:Timer = this.parallels.timerByLoader((e.target as LoaderInfo).loader)
			if (timer) {
				timer.stop();
			}
			this.tryLoadNext();
		}

		private function handleLoaderError(e:IOErrorEvent):void {
			var current:ResourceLoaderQueueObject = this.parallels.currentByLoader((e.target as LoaderInfo).loader);
			if (current) {
				var _currentUid:uint = current.uid;
				var _currentBundle:String = current.bundle;
				var _currentRequired:Boolean = current.required;
				var _currentRetries:uint = current.generalRetries;

				current.status = ResourceLoaderConstants.ERROR;
				this.cache.remove(current.url);
				if (_currentRetries < ResourceLoaderSettings.RESOURCE_LOADER_GENERAL_AUTO_RETRIES) {
					++current.generalRetries;
					current.status = ResourceLoaderConstants.PENDING;
					this.progress.push(current);
				}
				
				this.parallels.unsetCurrent(current);

				this.dispatchEvent(new ResourceLoaderFailEvent(_currentUid, e.toString()));
				this.tryAutoReset();
			}

			var timer:Timer = this.parallels.timerByLoader((e.target as LoaderInfo).loader)
			if (timer) {
				timer.stop();
			}
			this.tryLoadNext();
		}
	}
}
