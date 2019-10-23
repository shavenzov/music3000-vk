package classes.soundwave
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.IAudioData;
	
	import flash.display.Graphics;
	import flash.display.GraphicsPathCommand;
	
	public class SoundWaveGraphic extends BaseSoundWaveGraphic
	{
		public function SoundWaveGraphic(data:IAudioData, id:String, scalechange:Boolean, bpmChange:Boolean, color:uint=0x000000, alpha:Number=1.0)
		{
			super(data, id, scalechange, bpmChange, color, alpha);
		}
		
		/**
		 * Отрисовывает график звуковой волны на указанном Graphics 
		 * @param g
		 * @param w
		 * @param h
		 * @param dataOffset
		 * 
		 */		
		override protected function draw( g : Graphics, w : Number, halfHeight : Number, dataOffset : int, step : int, maxValue : Number = 2.0 ) : void
		{
			var ci : int = 0;
			var di : int = 0;
			var i   : int = 0;
			var _lastL : Number = 1.0;
			var _lastR : Number = 1.0;
			
			var cL : Number;
			var cR : Number;
			
			var l : Number;
			var r : Number;
			
			var _gcommands : Vector.<int>    = new Vector.<int>( w * 2 );
			var _gdata     : Vector.<Number> = new Vector.<Number>( w * 4 );
			
			//Определяем значение предыдущей выборки, для точного построения первой выборки
			var prevPos : int = AudioData.framesToBytes( dataOffset - step );
			
			if ( prevPos >= 0 )
			{
				_data.data.position = prevPos;
				_lastL = _data.data.readFloat() + 1.0;
				_lastR = _data.data.readFloat() + 1.0;
			}	
			
			while( i < w )
			{
				_data.data.position = AudioData.framesToBytes( dataOffset + i * step );
				
				l = _data.data.readFloat() + 1.0;
				r = _data.data.readFloat() + 1.0;
				
				cL = ( Math.abs( l - _lastL ) * halfHeight ) / maxValue;
				cR = ( Math.abs( r - _lastR ) * halfHeight ) / maxValue;	
				
				_lastL = l;
				_lastR = r;
				
				_gcommands[ ci ++ ] = GraphicsPathCommand.MOVE_TO;
				_gdata[ di ++ ]     = i;
				_gdata[ di ++ ]     = halfHeight;
				
				_gcommands[ ci ++ ] = GraphicsPathCommand.LINE_TO;
				_gdata[ di ++ ]     = i;
				_gdata[ di ++ ]     = halfHeight - cL;
				
				_gcommands[ ci ++ ] = GraphicsPathCommand.MOVE_TO;
				_gdata[ di ++ ]     = i;
				_gdata[ di ++ ]     = halfHeight;
				
				_gcommands[ ci ++ ] = GraphicsPathCommand.LINE_TO;
				_gdata[ di ++ ]     = i;
				_gdata[ di ++ ]     = halfHeight + cR;
				
				i ++;
			}
			/*
			g.beginFill( Math.random() * uint.MAX_VALUE );
			g.drawRect( 0, 0, i, halfHeight * 2.0 );
			g.endFill();
			*/
			g.lineStyle( 1.0, _color, _alpha );
			g.drawPath( _gcommands, _gdata );
			
		}	
	}
}