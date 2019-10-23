package test
{
	import com.audioengine.automatization.AutomatizationPoint;
	import com.audioengine.automatization.AutomatizationTrack;
	
	import flash.display.Sprite;
	import flash.utils.ByteArray;
	
	public class AutomatizationTrackTest extends Sprite
	{
		private var a : AutomatizationTrack;
		
		private var wWidth : Number = 100;
		
		public function AutomatizationTrackTest()
		{
			super();
			
			a = new AutomatizationTrack();
			
			a.duration = 1000;
			
			a.add( new AutomatizationPoint( 999, 0 ) );
			a.add( new AutomatizationPoint( 600, 70 ) );
			a.add( new AutomatizationPoint( 489, 88 ) );
			a.add( new AutomatizationPoint( 399, 0 ) );
			a.add( new AutomatizationPoint( 299, 50 ) );
			a.add( new AutomatizationPoint( 199, 50 ) );
			a.add( new AutomatizationPoint( 149, 100 ) );
			a.add( new AutomatizationPoint( 99, 25 ) );
			a.add( new AutomatizationPoint( 0, 33 ) );
			
			
			
			
			
			var pos  : Number = 0.0;
			var l    : Number;
			var data : ByteArray;
			
			while( pos < a.duration - 1 )
			{
				l = Math.min( a.duration - pos, wWidth ) - 1;
				
				data = a.copy( pos, pos + l );
				
				traceByteArray( data );
				
				
				pos += l + 1;
			}
		}
		
		private var zz : int = 0;
		
		private function traceByteArray( data : ByteArray ) : void
		{
			data.position = 0;
			/*
			trace();
			trace( 'block length', data.length );
			trace();
			*/
			while( data.bytesAvailable > 0 )
			{
				var d : Number = a.maxValue - a.minValue;
				
				var v : Number = d - data.readFloat();
				
				graphics.lineStyle( 1, 0xFF0000 );
				
				if ( zz == 0 )
				{
					graphics.lineStyle( 0, 0x0000FF, 0.5 );
					graphics.drawRect( 0.0, a.minValue, a.duration, a.maxValue - a.minValue );
					
					graphics.lineStyle( 1, 0x00FF00 );
					graphics.moveTo( 0.0, a.defaultValue );
					graphics.lineTo( a.duration, a.defaultValue );
					
					graphics.beginFill( 0x00FF00, 0.25 );
					
					for ( var i : int = 0; i < a.points.length; i ++ )
					{
						graphics.drawCircle( a.points[ i ].position, d - a.points[ i ].value, 2.0 );
					}
					
					graphics.endFill();
					
					graphics.lineStyle( 1, 0xFF0000 );
					graphics.moveTo( zz, v );
				}
				else
				{
					graphics.lineTo( zz, v );
				}
				
				trace( zz, d - v );
				
				zz ++;	
			}
		}
	}
}