package com.managers
{
	import mx.controls.ToolTip;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.effects.Tween;
	
	import components.managers.events.HintEvent;
	
	public class Hint extends ToolTip
	{
		public static const FADE_IN  : int = 2;
		public static const FADE_OUT : int = 4;
		public static const SHOWED   : int = 6;
		
		//анимационный tween
		private var _tween : Tween;
		//Время раскрытия/скрытия
		public var time  : Number = 500.0;
		/**
		 * Время отображения подсказки 
		 */		
		public var delayTime : Number = 2000.0;
		
		/**
		 * Текущий статус подсказки 
		 */		
		private var _status : int;
		private var _statusChanged : Boolean;
		
		public function Hint()
		{
			super();
			alpha = 0.0;
			show();
		}
		
		private var _toolTip : String;
		private var _errorString : String;
		private var _target : UIComponent;
		
		public function get target() : UIComponent
		{
			return _target;
		}
		
		public function set target( value : UIComponent):void
		{
			if ( _target )
			{
				_target.toolTip = _toolTip;
				_target.errorString = _errorString;
			}
			
		    if ( value )
			{
				_toolTip = value.toolTip;
				_errorString = value.errorString;
				
				value.toolTip = null;
				value.errorString = null;	
			}
			else
			{
				_toolTip = null;
				_errorString = null;
			}
			
			
			_target = value;
		}
		
		public function show() : void
		{
			setStatus( FADE_IN );
		}
		
		public function hide() : void
		{
			if ( _status != FADE_OUT )
			{
				setStatus( FADE_OUT );
			}	
		}	
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( _statusChanged )
			{
				
				if ( _tween )
				{
					_tween.stop();
				}	
				
				if ( _status == FADE_IN )
				{
					_tween = new Tween( this, alpha, 1.0, time );
				}
				else if ( _status == FADE_OUT )
				{
					_tween = new Tween( this, alpha, 0.0, time );
				}
				else if ( _status == SHOWED )
				{
					_tween = new Tween( this, 0, delayTime, delayTime );
				}
				
				_statusChanged = false;
				
			}	
		}	
		
		private function setStatus( status : int ) : void
		{
			_status = status;
			_statusChanged = true;
			invalidateProperties();
		}
		
		mx_internal function onTweenUpdate(value:Number):void
		{
			if ( _status == FADE_IN || _status == FADE_OUT )
			{
				alpha = value;
			}
		}
		
		mx_internal function onTweenEnd( value:Number ) : void
		{
			if ( _status == FADE_IN )
			{
				setStatus( SHOWED );
			}
			else if ( _status == SHOWED )
			{
				setStatus( FADE_OUT );
			}
			else if ( _status == FADE_OUT )
			{
				dispatchEvent( new HintEvent( HintEvent.HIDE ) );
			}	
		}
	}
}