package com.audioengine.sources
{
	import com.audioengine.core.IAudioData;
	
	import flash.events.IEventDispatcher;
	import flash.net.URLRequest;

	public interface IAudioDataSource extends IEventDispatcher
	{
		function load( request : URLRequest = null ) : void;
		function close() : void;
		
		function get request() : URLRequest
		function set request( value : URLRequest ) : void
		
		function get loading() : Boolean;	
		function get total() : int;
		function get progress() : int;
		function get source() : IAudioData;
		
		function get id() : String;
	}
}