package com.audioengine.automatization.easing
{
	import flash.display.Shader;
	
	import pbjAS.PBJ;
	import pbjAS.PBJAssembler;
	import pbjAS.PBJParam;
	import pbjAS.PBJType;
	import pbjAS.ops.OpAdd;
	import pbjAS.ops.OpCos;
	import pbjAS.ops.OpDiv;
	import pbjAS.ops.OpMov;
	import pbjAS.ops.OpMul;
	import pbjAS.ops.OpSub;
	import pbjAS.params.Parameter;
	import pbjAS.regs.RFloat;
	
	/*
	return -c / 2 * (Math.cos(Math.PI * t / d) - 1) + b;
	*/
	public class Sine extends EasingCalculation
	{
		
		
		public function Sine(length:int=0, height:int=-1)
		{
			super(length, height);
		}
		
		override protected function buildShader():void
		{
			super.buildShader();
			
			var pbj : PBJ = createEasingPBJ( 'autoSineTask' );
			
			pbj.parameters.push(
				
				//PI ( регистр 7 )
				new PBJParam( 'pi', new Parameter( PBJType.TFloat, false, new RFloat( 7, R ) ) ),
				//one ( регистр 8 )
				new PBJParam( 'one', new Parameter( PBJType.TFloat, false, new RFloat( 8, R ) ) ),
				//two ( регистр 9 )
				new PBJParam( 'two', new Parameter( PBJType.TFloat, false, new RFloat( 9, R ) ) )
			);
			
			pbj.code.push(
				
				/*алгоритм*/
				new OpMul( new RFloat( 11, R ), new RFloat( 7, R ) ), // t*pi
				new OpDiv( new RFloat( 11, R ), new RFloat( 6, R ) ),// ( t*pi ) / d
				new OpCos( new RFloat( 11, R ), new RFloat( 11, R ) ), // cos( ( t*pi ) / d )
				new OpSub( new RFloat( 11, R ), new RFloat( 8, R ) ), //  cos( ( t*pi ) / d ) - 1
				
				new OpMov( new RFloat( 10, R ), new RFloat( 5, R ) ), // -c
				new OpDiv( new RFloat( 10, R ), new RFloat( 9, R ) ), // -c/2
				
				new OpMul( new RFloat( 11, R ), new RFloat( 10, R ) ),
				new OpAdd( new RFloat( 11, R ), new RFloat( 4, R ) ),
				
				/*алгоритм*/
				
				
				//Перемещаем на выход
				new OpMov( new RFloat( 1, R ), new RFloat( 11, R ) )
			);
			
			
			//Собираем Shader
			_shader = new Shader( PBJAssembler.assemble( pbj ) );
		}
		
		override protected function propertyChanged() : void
		{
			super.propertyChanged();
			
			setValue( 'c', [ - _c ] );
			setValue( 'pi', [ Math.PI ] );
			setValue( 'one', [ 1.0 ] );
			setValue( 'two', [ 2.0 ] );
		}
	}
}