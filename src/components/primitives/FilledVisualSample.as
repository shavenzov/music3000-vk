/**
 * Базовый примитив для отрисовки семпла 
 */
package components.primitives
{
	import components.sequencer.baseClasses.FilledElement.BaseLoopableFilledElement;
	
	import flash.display.Graphics;
	
	public class FilledVisualSample extends BaseLoopableFilledElement
	{
		public function FilledVisualSample()
		{
			super();
			_timeDuration = NaN;
		    _loopDuration = NaN;
		}	
		
		private function drawRoundRect( g : Graphics, x : Number, y : Number, w : Number, h : Number ) : void
		{
			g.drawRoundRect( x, y, w, h, 34, 34 );	
		}
		
		override protected function draw(g:Graphics):void
		{
			if ( isNaN( _timeDuration ) )
			{
				drawRoundRect( g, 0, 0, width, height );
			}
			else
			{
				var x     : Number = 0;
				var count : Number = Math.ceil( _loopDuration / _timeDuration ) + 1;
				var sampleWidth : Number = _timeDuration / _scale;
				
				for ( var i : int = 0; i < count; i ++ )
				{
					if ( i == 0 )
					{
						//Вычисляем остаток слева
						var shift : Number = _localSampleOffset / _scale; 
						x += - shift;
						drawRoundRect( g, x, 0, sampleWidth, height );
					}
					else
					{
						drawRoundRect( g, x, 0, sampleWidth, height );
					}
					x += sampleWidth;
				}
			}
		 }	
	   }
}