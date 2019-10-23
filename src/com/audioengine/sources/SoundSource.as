package com.audioengine.sources
{
	import com.audioengine.core.AudioData;
	import com.audioengine.core.IAudioData;
	import com.thread.BaseRunnable;
	import com.thread.IRunnable;
	import com.thread.Thread;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	public class SoundSource extends EventDispatcher implements IAudioDataSource
	{
		/**
		 * Значение соответствующее 100 % загрузке 
		 */		
		private const _total  : int = 10000;
		
		/**
		 * Процентное соотношение одной из фаз загрузки 
		 */		
		private const _onephaze : int = _total / 2;
		
		/**
		 * Текущее значение состояния загрузки 
		 */		
		private var _progress : int = 0;
		
		private var _request : URLRequest;
		private var _loader  : URLLoader;
		protected var _encoder : Object;
		protected var _encoderClass : Class;
		private var _thread     : Thread;
		
		private var _source : AudioData;
		
		private var _loading : Boolean;
		
		private var _id   : String;
		private var _bpm  : Number;
		private var _loop : Boolean;
		
		public function SoundSource( request : URLRequest, id : String, bpm : Number, loop : Boolean )
		{
			super();
			_request = request;
			_id = id;
			_bpm = bpm;
			_loop = loop;
		}
		
		public function load( request : URLRequest = null ) : void
		{
			if ( ! request && ! _request )
			{
				throw new Error( "You haven't specified stream." );
			}
			
			if ( request ) _request = request;
			
			_loader = new URLLoader( _request );
			_loader.dataFormat = URLLoaderDataFormat.BINARY;
			_loader.addEventListener( ProgressEvent.PROGRESS, onProgress );
			_loader.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
			_loader.addEventListener( Event.COMPLETE, onComplete );
			
			_loading = true;
		}
		
		public function close() : void
		{
			if ( _loader )
			{
				_loader.close();
				_loader = null;
			}
			
			if ( _thread )
			{
			    _thread.destroy();
				_thread  = null;
				_encoder = null;
			}	
			
			_loading = false;
		}	
		
		private function removeListeners() : void
		{
			_loader.removeEventListener( ProgressEvent.PROGRESS, onProgress );
			_loader.removeEventListener( IOErrorEvent.IO_ERROR, onIOError );
			_loader.removeEventListener( Event.COMPLETE, onComplete );	
		}
		
		public function get total() : int 
		{
			return _total;
		}
		
		public function get progress() : int 
		{
			return _progress;
		}	
		
		private function onProgress( e : ProgressEvent ) : void
		{
			_progress = ( e.bytesLoaded * _onephaze ) / e.bytesTotal;
			dispatchEvent( new ProgressEvent( e.type, e.bubbles, e.cancelable, _progress, _total ) );
		}
		
		private function onIOError( e : IOErrorEvent ) : void
		{
			_loading = false;
			
			_progress = _total;
			removeListeners();
			dispatchEvent( e );
		}
		
		private function onComplete( e : Event ) : void
		{
			removeListeners();
			
			try
			{
				_encoder = new _encoderClass( _loader.data );
				_encoder.addEventListener( ErrorEvent.ERROR, encoderError );
				_encoder.addEventListener( ProgressEvent.PROGRESS, encoderProgress );
				_encoder.addEventListener( Event.COMPLETE, encoderComplete );
				
				_thread = new Thread( _encoder );
				_thread.start();	
			}
			catch( error : Error )
			{
				dispatchEvent( new ErrorEvent( ErrorEvent.ERROR, false, false, error.message, error.errorID ) );
			}
		}
		
		/**
		 * Высвобождает все задействованные ресурсы 
		 * 
		 */		
		private function finalize() : void
		{
			removeEncoderListeners();
			ByteArray( _loader.data ).clear(); //!!!
			_loader = null;
			
			_loading = false;
			_encoder  = null;
			_thread   = null;
			
			
			_progress = _total;
		}
		
		private function removeEncoderListeners() : void
		{
			_encoder.removeEventListener( ErrorEvent.ERROR, encoderError );
			_encoder.removeEventListener( ProgressEvent.PROGRESS, encoderProgress );
			_encoder.removeEventListener( Event.COMPLETE, encoderComplete );
		}	
		
		protected function encoderError( e : ErrorEvent ) : void
		{
			finalize();
			dispatchEvent( new ErrorEvent( e.type, e.bubbles, e.cancelable, e.text, e.errorID ) );
		}
		
		protected function encoderProgress( e : ProgressEvent ) : void
		{	
			_progress = _onephaze + ( e.bytesLoaded * _onephaze ) / e.bytesTotal;
			dispatchEvent( new ProgressEvent( e.type, e.bubbles, e.cancelable, _progress, _total ) );	
		}
		
		protected function encoderComplete( e : Event ) : void
		{
			//Если _bpm <= 0, то будем считать что значение bpm для сэмпла неизвестно
			var loaderAddition : Number = _bpm > 0 ? Routines.ceilLoop( _encoder.output, _bpm ) : 0.0;
			
			/*if ( loaderAddition > 0)
			{
				trace( loaderAddition );
			}*/
			
			_source = new AudioData( _id, _encoder.output, _bpm, _loop, loaderAddition );
			
			finalize();
			
			dispatchEvent( new ProgressEvent( ProgressEvent.PROGRESS, false, false, _total, _total ) );
			dispatchEvent( new Event( e.type, e.bubbles, e.cancelable ) );
		}	
		
		public function get id() : String
		{
			return _id;
		}
		
		public function get request() : URLRequest
		{
			return _request;
		}
		
		public function set request( value : URLRequest ) : void
		{
			_request = value;
		}
		
		public function get source() : IAudioData
		{
			return _source;
		}
		
		public function get loading() : Boolean
		{
			return _loading;
		}
	}
}