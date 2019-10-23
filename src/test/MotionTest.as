package test
{
	import flash.display.Sprite;
	
	import mx.effects.easing.Linear;
	
	public class MotionTest extends Sprite
	{
		public function MotionTest()
		{
			super();
			
			var v    : Number;
			var from : Number = 100;
			var to   : Number = 300;
			
			for( var i : int = 0; i < 100; i ++ )
			{
				v = Linear.easeNone( i, from, to, 100 )
				
				graphics.lineStyle( 1, 0xFF0000 );
				
				if ( i == 0 )
				{
					graphics.moveTo( i, v );
				}
				else
				{
					graphics.lineTo( i, v );
				}
				
				trace( i, v );
			}
		}
	}
}