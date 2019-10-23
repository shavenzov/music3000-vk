package test
{
	import com.audioengine.automatization.AutomatizationPoint;
	import com.audioengine.automatization.AutomatizationTrack;
	
	import flash.utils.ByteArray;
	
	import mx.core.UIComponent;
	
	import spark.core.IViewport;
	
	import components.sequencer.timeline.IScale;
	
	public class AutomatizationEditor extends UIComponent implements IViewport
	{
		private var _trackDataDecorator : AutomatizationTrackDecorator;
		private var _scale         : Number = 1000;
		
		private var _contentWidth  : Number;
		private var _contentHeight : Number;
		
		private var _hsp : Number = 0.0;
		private var _vsp : Number = 0.0; 
		
		public function AutomatizationEditor()
		{
			super();
		}

		public function get scale():Number
		{
			return _scale;
		}

		public function set scale(value:Number):void
		{
			if ( _scale != value )
			{
				_scale = value;
				
				if ( _trackDataDecorator )
				{
					_trackDataDecorator.scale = value;
				}
				
				invalidateDisplayList();
			}
		}

		public function get trackData():AutomatizationTrack
		{
			return _trackDataDecorator ? _trackDataDecorator.original : null;
		}

		public function set trackData( value : AutomatizationTrack ) : void
		{
			if ( value != trackData )
			{
				_trackDataDecorator       = new AutomatizationTrackDecorator( value );
				_trackDataDecorator.scale = _scale;
				
				invalidateDisplayList();
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			_contentHeight = unscaledHeight;
			_contentWidth  = _trackDataDecorator ? _trackDataDecorator.scaled.duration : 0.0;
		}
		
		private function getYValue( value : Number ) : Number
		{
			return unscaledHeight - ( value - _trackDataDecorator.scaled.minValue );
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			if ( ! trackData )
				return;
			
			var zz     : int    = 0;
			var from   : Number = _hsp;
			var to     : Number = _hsp + unscaledWidth;
			var a      : AutomatizationTrack = _trackDataDecorator.scaled;
			var points : Vector.<AutomatizationPoint> = a.getPoints( from, to );
			var data   : ByteArray = a.copy( from, to );
			    data.position = 0;
			
				graphics.clear();
				graphics.lineStyle( 0, 0x0000FF, 0.5 );
				graphics.drawRect( 0.0, getYValue( a.minValue ), a.duration, getYValue( a.maxValue ) );
				
				graphics.lineStyle( 1, 0x00FF00 );
				graphics.moveTo( 0.0, getYValue( a.defaultValue ) );
				graphics.lineTo( a.duration, getYValue( a.defaultValue ) );
				
				graphics.beginFill( 0x00FF00, 0.25 );
				
				for ( var i : int = 0; i < points.length; i ++ )
				{
					graphics.drawCircle( points[ i ].position, getYValue( a.points[ i ].value ), 2.0 );
				}
				
				graphics.endFill();
				
				graphics.lineStyle( 1, 0xFF0000 );	
				
			while( data.bytesAvailable > 0 )
			{
				var v : Number = data.readFloat();
				
				if ( zz == 0 )
				{
					
					graphics.moveTo( zz, getYValue( v ) );
				}
				else
				{
					graphics.lineTo( zz, getYValue( v ) );
				}
				
				zz ++;	
			}
		}
		
		public function get contentWidth():Number
		{
			return _contentWidth;
		}
		
		public function get contentHeight():Number
		{
			return _contentHeight;
		}
		
		public function get horizontalScrollPosition():Number
		{
			return _hsp;
		}
			
		public function set horizontalScrollPosition(value:Number):void
		{
			_hsp = value;
		}
		
		
		public function get verticalScrollPosition():Number
		{
			return _vsp;
		}
		
		public function set verticalScrollPosition(value:Number):void
		{
			_vsp = value;
		}
		
		public function getHorizontalScrollPositionDelta(navigationUnit:uint):Number
		{
			return 0.0;
		}
		
		public function getVerticalScrollPositionDelta(navigationUnit:uint):Number
		{
			return 0.0; 
		}
		
		public function get clipAndEnableScrolling():Boolean
		{
			return true;
		}
		
		public function set clipAndEnableScrolling(value:Boolean):void
		{
			
		}
	}
}