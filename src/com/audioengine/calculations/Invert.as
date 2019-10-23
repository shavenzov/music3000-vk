package com.audioengine.calculations
{
	import flash.display.Shader;
	import flash.utils.ByteArray;
	
	import pbjAS.PBJ;
	import pbjAS.PBJAssembler;
	import pbjAS.PBJParam;
	import pbjAS.PBJType;
	import pbjAS.ops.OpMov;
	import pbjAS.ops.OpSampleNearest;
	import pbjAS.ops.OpSub;
	import pbjAS.params.Parameter;
	import pbjAS.params.Texture;
	import pbjAS.regs.RFloat;

	public class Invert extends Calculation
	{
		private var _input : ByteArray;
		
		public function Invert(length:int=0)
		{
			super(length);
		}
		
		public function get input() : ByteArray
		{
			return _input;
		}
		
		public function set input( value : ByteArray ) : void
		{
			_input = value;
			_propertyChanged = true;
		}
		
		override protected function buildShader():void
		{	
			super.buildShader();
			
			var pbj : PBJ = createPBJ( 'inverseTask' );
			
			
			pbj.parameters.push( 
				               //Входные данные (Индекс 0)
				               new PBJParam( 'sample', new Texture( 2, 0 ) )
							   );
			
			pbj.parameters.push(
							   //Размер входных данных (регистр 1 )
				               new PBJParam( 'size', new Parameter( PBJType.TFloat2, false, new RFloat( 1, _channels ) ) )
							 ); 
			
			/*код  (регистр3 - промежуточный регистр)*/
			pbj.code = [
				         new OpMov( new RFloat( 3, _channels ), new RFloat( 1, _channels ) ), //r3 = size;
						 new OpSub( new RFloat( 3, _channels ), new RFloat( 0, _channels ) ), //r3 -= outCoord();
						 new OpSampleNearest( new RFloat( 2, _channels), new RFloat( 3, _channels ), 0 ) //out = getSampleNearest( r3 );
				       ];
				
			//Добавляем выход (регистр 2 )
			addOutput( pbj, 2 );
			
			//Собираем Shader
			_shader = new Shader( PBJAssembler.assemble( pbj ) );
		}
		
		override protected function propertyChanged():void
		{
			super.propertyChanged();
			
			setData( 'sample', _input );
			setValue( 'size', [ _length / _height, _height ] );
		}	
		
	}
}