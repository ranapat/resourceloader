package org.ranapat.resourceloader {
	import flash.display.Loader;
	import flash.utils.Timer;
	
	internal class ResourceLoaderParallels {
		private var queue:Vector.<ResourceLoaderParallelsObject>;
		
		public function ResourceLoaderParallels() {
			this.queue = new Vector.<ResourceLoaderParallelsObject>(ResourceLoaderSettings.RESOURCE_LOADER_PARALLEL_LOADERS, true);
			
			for (var i:uint = 0; i < ResourceLoaderSettings.RESOURCE_LOADER_PARALLEL_LOADERS; ++i) {
				this.queue[i] = new ResourceLoaderParallelsObject();
			}
		}
		
		public function get(index:uint):ResourceLoaderParallelsObject {
			return index < ResourceLoaderSettings.RESOURCE_LOADER_PARALLEL_LOADERS? this.queue[index] : null;
		}
		
		public function currentByTimer(timer:Timer):ResourceLoaderQueueObject {
			for (var i:uint = 0; i < ResourceLoaderSettings.RESOURCE_LOADER_PARALLEL_LOADERS; ++i) {
				if (this.queue[i].timer == timer) {
					return this.queue[i].current;
				}
			}
			return null;
		}
		
		public function loaderByTimer(timer:Timer):Loader {
			for (var i:uint = 0; i < ResourceLoaderSettings.RESOURCE_LOADER_PARALLEL_LOADERS; ++i) {
				if (this.queue[i].timer == timer) {
					return this.queue[i].loader;
				}
			}
			return null;
		}
		
		public function unsetCurrent(current:ResourceLoaderQueueObject):void {
			for (var i:uint = 0; i < ResourceLoaderSettings.RESOURCE_LOADER_PARALLEL_LOADERS; ++i) {
				if (this.queue[i].current == current) {
					this.queue[i].current = null;
					
					break;
				}
			}
		}

		
		public function currentByLoader(loader:Loader):ResourceLoaderQueueObject {
			for (var i:uint = 0; i < ResourceLoaderSettings.RESOURCE_LOADER_PARALLEL_LOADERS; ++i) {
				if (this.queue[i].loader == loader) {
					return this.queue[i].current;
				}
			}
			return null;
		}
		
		public function timerByLoader(loader:Loader):Timer {
			for (var i:uint = 0; i < ResourceLoaderSettings.RESOURCE_LOADER_PARALLEL_LOADERS; ++i) {
				if (this.queue[i].loader == loader) {
					return this.queue[i].timer;
				}
			}
			return null;
		}
		
		public function get length():uint {
			return ResourceLoaderSettings.RESOURCE_LOADER_PARALLEL_LOADERS;
		}
		
		public function get anyFree():Boolean {
			for (var i:uint = 0; i < ResourceLoaderSettings.RESOURCE_LOADER_PARALLEL_LOADERS; ++i) {
				if (!this.queue[i].timer.running) {
					return true;
				}
			}
			return false;
		}
		
		public function get free():ResourceLoaderParallelsObject {
			for (var i:uint = 0; i < ResourceLoaderSettings.RESOURCE_LOADER_PARALLEL_LOADERS; ++i) {
				if (!this.queue[i].timer.running) {
					return this.queue[i];
				}
			}
			return null;
		}
	}

}