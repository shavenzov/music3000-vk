package components.sequencer.timeline
{
	import com.audioengine.core.TimeConversion;
	import components.Scroller;
	import components.sequencer.timeline.events.MarkerChangeEvent;
	import components.sequencer.timeline.events.ScrollToEvent;
	import components.sequencer.timeline.events.TracingEvent;
	import classes.SequencerImplementation;
	
	import flash.utils.setInterval;
	
	import mx.events.FlexEvent;
	
	import spark.events.TrackBaseEvent;
	
	public class ScrollableTimeLine extends Scroller
	{
		public var timeline : TimeLine;
		/**
		 * Область отображения, всегда будет следовать за курсором воспроизведения 
		 */		
		//public var scrollMode : uint = TimeLineScrollMode.SCROLL_ON_LEFT_AND_RIGHT_AREA;
		
		/**
		 * Указывает что пользователь выполняет какие-то действия с горизонтальной полосой прокрутки 
		 */		
		private var _hScrollBarPressed : Boolean;
		
		/**
		 * Ссылка на синглтон управления секвенсором 
		 */		
		private var _seq : SequencerImplementation;
		
		public function ScrollableTimeLine()
		{
			super();
			focusEnabled = false;
			tabEnabled = false;
			_seq = classes.Sequencer.impl;
			measuredSizeIncludesScrollBars = true;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			timeline = new TimeLine();
			timeline.percentWidth = 100;
			timeline.percentHeight = 100;
			
			viewport = timeline;
			
			horizontalScrollBar.addEventListener( TrackBaseEvent.THUMB_PRESS, onHScrollBarPress );
			horizontalScrollBar.addEventListener( TrackBaseEvent.THUMB_RELEASE, onHScrollBarRelease );
		}
		
		private function onHScrollBarPress( e : TrackBaseEvent ) : void
		{
			_hScrollBarPressed = true;
		}
		
		private function onHScrollBarRelease( e : TrackBaseEvent ) : void
		{
			_hScrollBarPressed = false;
		}
		
		public function scrollToPosition( position : Number, scrollMode : int/*, param : Number*/ ) : void
		{
			if ( scrollMode == TimeLineScrollMode.NO_SCROLL || _hScrollBarPressed || timeline._tracing ) return;
			
			var viewX     : Number = timeline.horizontalScrollPosition;
			var viewWidth : Number = timeline.width;
			var maxViewX  : Number = timeline.contentWidth - viewWidth;
			
			var scrollX   : Number;
			
			if ( scrollMode == TimeLineScrollMode.PLAYHEAD_CENTERED )
			{
				scrollX = position - ( viewWidth / 2 );
			}
			else if ( scrollMode == TimeLineScrollMode.SCROLL_ON_NEXT_VIEW )
			{
				//Проверяем вышел ли курсор за границы видимости
				if ( ( position < viewX ) || ( position > viewX + viewWidth ) )
				{
					if ( _seq.inverse )
					{
						scrollX = position - viewWidth;
					}
					else
					{
						scrollX = position;
					}	
				}
				else return;
			}/*
			else if ( scrollMode == TimeLineScrollMode.SCROLL_ON_LEFT_AND_RIGHT_AREA )
			{
				var autoScrollArea : Number = param - 10;
				
				if ( position > viewX + viewWidth - autoScrollArea )
				{
					scrollX = position - viewWidth + autoScrollArea;
				}	
				else if ( position < viewX + autoScrollArea )
				{
					scrollX = viewX - ( autoScrollArea - ( position - viewX ) );
				}
				else return;
			}*/
			
			//Корректировка
			if ( scrollX < 0 )
			{
				scrollX = 0;
				
			}	
			else if ( scrollX > maxViewX )
			{
				scrollX = maxViewX;
				
			}
			
			timeline.horizontalScrollPosition = scrollX;	
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList( unscaledWidth, unscaledHeight );
			
			vScrollBarTop = timeline.rullerHeight;
		}		
		
	}
}