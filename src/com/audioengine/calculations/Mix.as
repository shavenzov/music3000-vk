/**
 * Смешивает значение выборок в каждом образце по ф-ле dst = ( src1 + src2 ... + srcN ) / N; 
 */
package com.audioengine.calculations
{
	import flash.display.Shader;
	import flash.utils.ByteArray;
	
	import pbjAS.PBJ;
	import pbjAS.PBJAssembler;
	import pbjAS.PBJParam;
	import pbjAS.ops.OpAdd;
	import pbjAS.ops.OpSampleNearest;
	import pbjAS.params.Texture;
	import pbjAS.regs.RFloat;

	public class Mix extends Calculation
	{
		/**
		 * Количество образцов которые будут смешаны 
		 */		
		private var _samples  : Vector.<ByteArray>;
		
		public function Mix(length:int=0)
		{
			super(length);
		}
		
		public function get samples() : Vector.<ByteArray>
		{
			return _samples;
		}
		
		public function set samples( value : Vector.<ByteArray> ) : void
		{	
			_samples = value;
			_needRebuild = true;
			_propertyChanged = true;	
		}
		
		override protected function buildShader():void
		{
			super.buildShader();
			
			var i          : int = 0;
			var numSamples : int = _samples.length;
			
			var pbj : PBJ = createPBJ( 'mixingTask' );
			
			while( i < numSamples )
			{
				//Образцы для входа
				pbj.parameters.push( new PBJParam( 'sample' + i, new Texture( 2, i ) ) );
				
				//Код для смешивания этого образца
				if ( i == 0 )
				{
					pbj.code.push( new OpSampleNearest( new RFloat( 2, _channels ), new RFloat( 0, _channels ), i ) ); //output = t(0)
				}	
				else
				{
					pbj.code.push( new OpSampleNearest( new RFloat( 3, _channels ), new RFloat( 0, _channels ), i ) ); // v3 = t(i);
					pbj.code.push( new OpAdd( new RFloat( 2, _channels ), new RFloat( 3, _channels ) ) ); // output = output + v3;	
				}
				
				i ++;
			}	
			
			//Добавляем выход
			addOutput( pbj, 2 );
			
			//Собираем Shader
			_shader = new Shader( PBJAssembler.assemble( pbj ) );
		}
		
		override protected function propertyChanged() : void
		{
		  super.propertyChanged();
		  
		  var numSamples : int = _samples.length;
		  var i          : int = 0;
		  
		  //Устанавливаем входные параметры
		  while( i < numSamples )
		  {
			  setData( 'sample' + i, _samples[ i ] );
			  
			  i ++;
		  }
		}	
	}
}