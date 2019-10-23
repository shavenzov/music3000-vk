package com.audioengine.automatization.easing
{
	import flash.display.Shader;
	
	import pbjAS.PBJ;
	import pbjAS.PBJAssembler;
	import pbjAS.ops.OpAdd;
	import pbjAS.ops.OpDiv;
	import pbjAS.ops.OpMov;
	import pbjAS.ops.OpMul;
	import pbjAS.regs.RFloat;
	
	/*
	return c * t / d + b;
	*/
	public class Linear extends EasingCalculation
	{
		public function Linear(length:int=0, height:int=-1)
		{
			super(length, height);
		}

		override protected function buildShader():void
		{
			super.buildShader();
			
			var pbj : PBJ = createEasingPBJ( 'autoLinearTask' );
			
			pbj.code.push(
				
				
				new OpMul( new RFloat( 11, R ), new RFloat( 5, R ) ), //t *c 
				new OpDiv( new RFloat( 11, R ), new RFloat( 6, R ) ), //  /d
				new OpAdd( new RFloat( 11, R ), new RFloat( 4, R ) ),  // + b
				
				//Перемещаем на выход
				new OpMov( new RFloat( 1, R ), new RFloat( 11, R ) )
				
				);
			
			//Собираем Shader
			_shader = new Shader( PBJAssembler.assemble( pbj ) );
		}
		
		

	}
}