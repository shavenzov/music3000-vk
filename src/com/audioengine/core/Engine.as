package com.audioengine.core
{
	import flash.utils.ByteArray;

	public class Engine implements IProcessor, IInput
	{
		private const _processors : Vector.<IProcessor> = new Vector.<IProcessor>();
		private var _input : IProcessor;
		
		public function Engine()
		{
		}
		
		public function get input() : IProcessor
		{
			return _input;
		}
		
		public function set input( value : IProcessor ) : void
		{
			_input = value;
		}	
		
		public function add( processor : IProcessor ) : void
		{
			_processors.push( processor ); 
		}
		
		public function remove( processor : IProcessor ) : void
		{	
			var i : int = 0;
			
			while( i < _processors.length )
			{
				if ( _processors[ i ] == processor )
				{
					_processors.splice( i, 1 );
				}	
				i ++;
			}	
		}
		
		public function render( data : ByteArray, bytes : uint ) : void
		{
			if ( _input )
			{
				
			}	
		}	
	}
}