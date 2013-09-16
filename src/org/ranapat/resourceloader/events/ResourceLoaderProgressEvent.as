package org.ranapat.resourceloader.events {
	import flash.events.Event;
	
	public class ResourceLoaderProgressEvent extends Event {
		public static const TYPE:String = "resourceLoaderProgress";
		
		public var uid:uint;
		public var progress:Number;
		public var bundle:String;
		
		public function ResourceLoaderProgressEvent(uid:uint, progress:Number, bundle:String) {
			super(ResourceLoaderProgressEvent.TYPE);
			
			this.uid = uid;
			this.progress = progress;
			this.bundle = bundle;
		}
		
	}

}