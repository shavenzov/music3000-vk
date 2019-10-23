package components.hslider
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.controls.sliderClasses.SliderThumb;
	import mx.core.mx_internal;
	import mx.effects.Tween;
	import mx.events.SliderEvent;
	import mx.events.SliderEventClickTarget;
	
	use namespace mx_internal;

	public class TempoSlider extends HSlider
	{
		private var lastX : Number;
		private var lastV : Number;
		private var d : Number = NaN;
		
		public function TempoSlider()
		{
			super();
			
			addEventListener( SliderEvent.THUMB_PRESS, onThumbPress );
			addEventListener( SliderEvent.THUMB_RELEASE, onThumbRelease );
			addEventListener( SliderEvent.THUMB_DRAG, onThumbDrag );
			addEventListener( SliderEvent.CHANGE, onChange, false, 1000 );
		}
		
		override protected function track_mouseDownHandler(event:MouseEvent):void
		{
			if (event.target != trackHitArea && event.target != ticks)
				return;
			if (enabled && allowTrackClick)
			{
				interactionClickTarget = SliderEventClickTarget.TRACK;
				//this is a mouse event
				keyInteraction = false;
				var pt:Point = new Point(event.localX, event.localY);
				var xM:Number = pt.x;
				var minIndex:Number = 0;
				var minDistance:Number = 10000000;
				
				// find the nearest thumb
				var n:int = _thumbCount;
				for (var i:int = 0; i < n; i++)
				{
					var d:Number = Math.abs(SliderThumb(thumbs.getChildAt(i)).xPosition - xM);
					if (d < minDistance)
					{
						minIndex = i;
						minDistance = d;
					}
				}
				var thumb:SliderThumb = SliderThumb(thumbs.getChildAt(minIndex));
				if (!isNaN(_snapInterval) && _snapInterval != 0)
				{
					var v  : Number = getValueFromX( xM );
					var v1 : Number = getNext( v );
					var v2 : Number = getPrev( v );
					
					if ( ( v1 - v ) >= ( v - v2 ) )
					{
						v = v2;
					}
					else
					{
						v = v1;
					}
					
					xM = getXFromValue( v );
				}	
					
				
				var duration:Number = getStyle("slideDuration");
				var t:Tween = new Tween(thumb, thumb.xPosition, xM, duration);
				
				var easingFunction:Function = getStyle("slideEasingFunction") as Function;
				if (easingFunction != null)
					t.easingFunction = easingFunction;
				
				drawTrackHighlight();
			}
		}
		
		private function onChange( e : SliderEvent ) : void
		{
			if ( ! isNaN( d ) ) e.stopImmediatePropagation();
		}
		
		private function onThumbDrag( e : SliderEvent ) : void
		{
			d = mouseX - lastX;
			lastX = mouseX;
		}
		
		private function onThumbPress( e : SliderEvent ) : void
		{
			lastX = mouseX;
			lastV = values[ e.thumbIndex ];
		}
		
		private function onThumbRelease( e : SliderEvent ) : void
		{
			if ( e.value == lastV )
			{
				d = NaN;
				return;
			}
			
			var v : Number = values[ e.thumbIndex ];
			
			if ( d < 0 )
			{
				v = getPrev( v );
			}
			else
			{
				v = getNext( v );
			}
			
			var cV : Number = e.thumbIndex == 0 ? values[ 1 ] : values [ 0 ];
			
			if ( cV == v )
			{
				v = lastV;
			}	
			
            if ( e.value == v )
			{
				d= NaN;
				dispatchEvent( new SliderEvent( SliderEvent.CHANGE, false, false, e.thumbIndex, e.value ) );
			}
			else
			{
				moveThumbAt( e.thumbIndex, v );
				d= NaN;
			}
			
			
		}
		
		private function getNext( v : Number ) : Number
		{
			var i : int = 0;
			var result : Number = maximum;
			
			while( i < tickValues.length )
			{
				if ( tickValues[ i ] >= v )
				{
					result = Math.min( tickValues[ i ], result );
				}	
				
				i ++;
			}
			
			return result;
		}
		
		private function getPrev( v : Number ) : Number
		{
			var i : int = 0;
			var result : Number = minimum;
			
			while( i < tickValues.length )
			{
				if ( tickValues[ i ] <= v )
				{
					result = Math.max( tickValues[ i ], result );
				}	
				
				i ++;
			}
			
			return result;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			var i : int = 0;
			var thumb : SliderThumb;
			
			while( i < values.length )
			{
				thumb = getThumbAt( i );
				thumb.focusEnabled = false;
				thumb.tabEnabled = false;
				
				i ++;
			}
		}
	}
}