package org.ranapat.resourceloader.events {
	import flash.events.Event;
	
	public class ResourceLoaderFailEvent extends Event {
		public static const TYPE:String = "resourceLoaderFail";
		
		public var uid:uint;
		public var reason:String;
		public var bundle:String;
		
		public function ResourceLoaderFailEvent(uid:uint, reason:String, bundle:String) {
			super(ResourceLoaderFailEvent.TYPE);
			
			this.uid = uid;
			this.reason = reason;
			this.bundle = bundle;
		}
		
	}

}