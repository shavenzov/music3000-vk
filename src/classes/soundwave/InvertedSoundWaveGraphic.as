package classes.soundwave
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.IAudioData;
	
	import flash.display.Graphics;
	import flash.display.GraphicsPathCommand;
	
	public class InvertedSoundWaveGraphic extends BaseSoundWaveGraphic
	{
		public function InvertedSoundWaveGraphic(data:IAudioData, id:String, scalechange:Boolean, bpmChange:Boolean, color:uint=0xFFFFFF, alpha:Number=1.0)
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
			var _lastL : Number;
			var _lastR : Number;
			
			var cL : Number = 0.0;
			var cR : Number = 0.0;
			
			var l : Number;
			var r : Number;
			
			var _gcommands : Vector.<int>    = new Vector.<int>( w * 2 );
			var _gdata     : Vector.<Number> = new Vector.<Number>( w * 4 );
			
			//Определяем значение предыдущей выборки, для точного построения первой выборки
			var prevPos : int = AudioData.framesToBytes( _data.length - dataOffset - step ) - AudioData.BYTES_PER_SAMPLE;
			
			if ( prevPos < _data.length )
			{
				_data.data.position = prevPos;
				_lastL = _data.data.readFloat() + 1.0;
				_lastR = _data.data.readFloat() + 1.0;
			}
			
			while( i < w )
			{
				_data.data.position = AudioData.framesToBytes( _data.length - ( dataOffset + i * step ) ) - AudioData.BYTES_PER_SAMPLE;
				
				l = _data.data.readFloat() + 1.0;
				r = _data.data.readFloat() + 1.0;
				
				if ( i != 0 )
				{
					cL = ( Math.abs( l - _lastL ) * halfHeight ) / 2.0;
					cR = ( Math.abs( r - _lastR ) * halfHeight ) / 2.0;
				}	
				
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
			
			g.lineStyle( 1.0, _color, _alpha );
			g.drawPath( _gcommands, _gdata );
		}	
	}
}