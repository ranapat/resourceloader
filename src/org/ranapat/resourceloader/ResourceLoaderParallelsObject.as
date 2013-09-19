package org.ranapat.resourceloader {
	import flash.display.Loader;
	import flash.utils.Timer;
	
	internal class ResourceLoaderParallelsObject {
		public var timer:Timer;
		public var loader:Loader;
		public var current:ResourceLoaderQueueObject;
		
		public function ResourceLoaderParallelsObject() {
			this.timer = new Timer(ResourceLoaderSettings.RESOURCE_LOADER_TIMEOUT_INTERVAL, 1);
			this.loader = new Loader();
			this.current = null;
		}
		
	}

}