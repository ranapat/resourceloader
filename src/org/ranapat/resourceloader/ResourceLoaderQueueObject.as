package org.ranapat.resourceloader
{
	internal class ResourceLoaderQueueObject {
		public var uid:uint;
		public var url:String;
		public var status:uint;
		public var setSize:Number;
		public var bundle:String;
		public var required:Boolean;
		public var parameters:Vector.<String>;
		public var bytesTotal:Number;
		public var bytesLoaded:Number;

		public function ResourceLoaderQueueObject(
			uid:uint,
			url:String,
			setSize:Number,
			bundle:String,
			required:Boolean,
			parameters:Vector.<String>
		) {
			this.uid = uid;
			this.url = url;
			this.setSize = setSize;
			this.bundle = bundle;
			this.required = required;
			this.parameters = parameters;

			this.bytesTotal = 0;
			this.bytesLoaded = 0;
			this.status = ResourceLoaderConstants.PENDING;
		}

		public function get progress():Number {
			return this.bytesTotal == 0? 0 : this.bytesLoaded / this.bytesTotal * 100;
		}
	}
}
