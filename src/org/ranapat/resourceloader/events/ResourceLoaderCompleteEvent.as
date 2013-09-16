package org.ranapat.resourceloader.events {
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	
	public class ResourceLoaderCompleteEvent extends Event {
		public static const TYPE:String = "resourceLoaderComplete";
		
		public var uid:uint;
		public var loaderTarget:Object;
		public var applicationDomain:ApplicationDomain;
		
		public function ResourceLoaderCompleteEvent(uid:uint, loaderTarget:Object, applicationDomain:ApplicationDomain) {
			super(ResourceLoaderCompleteEvent.TYPE);
			
			this.uid = uid;
			this.loaderTarget = loaderTarget;
			this.applicationDomain = applicationDomain;
		}
		
	}

}