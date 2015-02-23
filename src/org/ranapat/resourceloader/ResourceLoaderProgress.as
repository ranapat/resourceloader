package org.ranapat.resourceloader {
	
	internal class ResourceLoaderProgress{
		private var queue:Vector.<ResourceLoaderQueueObject>;
		private var _index:int;

		public function ResourceLoaderProgress() {
			this.reset();
		}
		
		public function get index():int {
			return _index;
		}
		
		public function get next():ResourceLoaderQueueObject {
			return this.index < this.queue.length - 1? this.queue[++this._index] : null;
		}

		public function get current():ResourceLoaderQueueObject {
			return this.index >= 0 && this.index < this.queue.length? this.queue[this.index] : null;
		}

		public function reset():void {
			this.queue = new Vector.<ResourceLoaderQueueObject>();
			this._index = -1;
		}

		public function push(tmp:ResourceLoaderQueueObject):void {
			this.queue.push(tmp);
		}

		public function pushAfterIndex(tmp:ResourceLoaderQueueObject):void {
			this.queue.splice(this._index + 1, 0, tmp);
		}

		public function getProgress(bundle:String):Number {
			var loaded:Number = 0;
			var total:Number = 0;

			var _queue:Vector.<ResourceLoaderQueueObject> = this.queue;
			var length:uint = _queue.length;
			var tmp:ResourceLoaderQueueObject;
			for (var i:uint = 0; i < length; ++i) {
				tmp = _queue[i];
				if (tmp.bundle == bundle) {
					total += tmp.setSize;
					loaded += tmp.setSize * tmp.progress / 100;
				}
			}
			
			return loaded / total * 100;
		}
		
		public function anyBundleInProgress():Boolean {
			var complete:Boolean = false;

			var _queue:Vector.<ResourceLoaderQueueObject> = this.queue;
			var length:uint = _queue.length;
			var tmp:ResourceLoaderQueueObject;
			for (var i:uint = 0; i < length && !complete; ++i) {
				tmp = _queue[i];
				if (
					tmp.status == ResourceLoaderConstants.PENDING
					|| tmp.status == ResourceLoaderConstants.LOADING
				) {
					complete = true;
				}
			}

			return complete;
		}

		public function isBundleNotInProgress(bundle:String):Boolean {
			var complete:Boolean = true;

			var _queue:Vector.<ResourceLoaderQueueObject> = this.queue;
			var length:uint = _queue.length;
			var tmp:ResourceLoaderQueueObject;
			for (var i:uint = 0; i < length && complete; ++i) {
				tmp = _queue[i];
				if (
					tmp.bundle == bundle
					&& (
						tmp.status == ResourceLoaderConstants.PENDING
						|| tmp.status == ResourceLoaderConstants.LOADING
					)
				) {
					complete = false;
				}
			}

			return complete;
		}

		public function haveRequired(bundle:String):Boolean {
			var present:Boolean = false;

			var _queue:Vector.<ResourceLoaderQueueObject> = this.queue;
			var length:uint = _queue.length;
			var tmp:ResourceLoaderQueueObject;
			for (var i:uint = 0; i < length && !present; ++i) {
				tmp = _queue[i];
				if (
					tmp.bundle == bundle
					&& tmp.required
				) {
					present = true;
				}
			}

			return present;
		}

		public function isRequiredPending(bundle:String):Boolean {
			var pending:Boolean = false;

			var _queue:Vector.<ResourceLoaderQueueObject> = this.queue;
			var length:uint = _queue.length;
			var tmp:ResourceLoaderQueueObject;
			for (var i:uint = 0; i < length && !pending; ++i) {
				tmp = _queue[i];
				if (
					tmp.bundle == bundle
					&& tmp.required == true
					&& tmp.status == ResourceLoaderConstants.PENDING
				) {
					pending = true;
				}
			}

			return pending;
		}

		public function getParameters(uid:uint):Vector.<String> {
			var _queue:Vector.<ResourceLoaderQueueObject> = this.queue;
			var length:uint = _queue.length;
			var tmp:ResourceLoaderQueueObject;
			for (var i:uint = 0; i < length; ++i) {
				tmp = _queue[i];
				if (tmp.uid == uid) {
					return tmp.parameters;
				}

			}

			return null;
		}
	}
}
