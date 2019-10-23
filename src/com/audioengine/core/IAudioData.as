package com.audioengine.core
{
	import flash.events.IEventDispatcher;
	import flash.utils.ByteArray;

	public interface IAudioData extends IEventDispatcher
	{
		function get locked() : Boolean;
		function set locked( value : Boolean ) : void
		
		function get data() : ByteArray;
		
		function get length() : Number;
		
		function get bpm() : Number;
		
		function get loop() : Boolean;
		
		function get id() : String;
		
		/**
		 * Количество выборок добавленных загрузчиком для выравнивания до целого числа ударов 
		 */
		function get loaderAddition() : Number; 
		
		function copy( buffer : ByteArray, srcOffset : Number, dstOffset : Number, length : Number, params : Object = null ) : void	
			
		function clone() : IAudioData;
		
		function dispose() : void;
	}
}