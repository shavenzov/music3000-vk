package com.audioengine.processors
{
	import com.audioengine.calculations.Mix;
	import com.audioengine.core.IProcessor;
	
	import flash.utils.ByteArray;

	public class Combiner implements IProcessor
	{
		/**
		 * Список входов для смешивания 
		 */		
		private var inputs : Vector.<IProcessor> = new Vector.<IProcessor>();
		
		/**
		 * Данные для микширования 
		 */		
		private const _data   : Vector.<ByteArray> = new Vector.<ByteArray>();
		
		/**
		 * Нулевые данные 
		 */		
		private const zeroBytes: ByteArray = new ByteArray();
		
		private var mix : Mix = new Mix();
		
		public function Combiner()
		{
		}
		
		public function add( device : IProcessor ) : void
		{
			inputs.push( device ); 
			_data.push( new ByteArray() );
			mix.samples = _data;
		}
		
		public function remove( device : IProcessor ) : void
		{
			var i : int = 0;
			
			while( i < inputs.length )
			{
				var input : IProcessor = inputs[ i ];
				
				if ( input == device )
				{	
					inputs.splice( i, 1 );
					_data.splice( i, 1 );
					mix.samples = _data;
					return;
				}
				
				i ++;
			}	
		}	
		
		public function render(data:ByteArray, bytes:uint):void
		{
			if ( inputs.length > 0 )
			{
				var i : int = 0;
				
				while( i < inputs.length )
				{
					_data[ i ].position = 0;
					_data[ i ].length = bytes;
					inputs[ i ].render( _data[ i ], bytes );
					
					i ++;
				}
				
				//Вычисляем
				mix.bytesLength = bytes;
				mix.calculate( data );
				
			}
			else
			{
				zeroBytes.length = bytes;
				data.writeBytes( zeroBytes );
			}	  
		}	
	}
}