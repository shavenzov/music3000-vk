package com.audioengine.format.tasks
{
	import com.thread.IRunnable;
	
	import flash.utils.ByteArray;
	
	public interface IEncoder extends IRunnable
	{
		function get statusString() : String;
		function get status() : int;
		function get outputData() : ByteArray;
		function get rawData() : ByteArray;
		function set rawData( value : ByteArray ) : void;
		
		function calcTotal( rawDataLength : int ) : int;
		function clear() : void;	
	}
}