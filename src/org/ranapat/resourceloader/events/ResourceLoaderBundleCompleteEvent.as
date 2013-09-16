package org.ranapat.resourceloader.events {
	import flash.events.Event;
	
	public class ResourceLoaderBundleCompleteEvent extends Event {
		public static const TYPE:String = "resourceLoaderBundleComplete";
		
		public var bundle:String;
		
		public function ResourceLoaderBundleCompleteEvent(bundle:String) {
			super(ResourceLoaderBundleCompleteEvent.TYPE);
			
			this.bundle = bundle;
		}
		
	}

}