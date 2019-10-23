/**
 * Организует мониторинг общего состояния загрузки ресурса 
 */
package com.audioengine.sources
{
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	
	public class SourceLoaderManager extends EventDispatcher
	{
		/**
		 * Список загружаемых в данный момент источников 
		 */		
		private var _loaders : Vector.<IAudioDataSource>;
		
		private var _total : int;
		private var _progress : int;
		
		private var _totalLoaded   : int;
		private var _successLoaded : int;
		private var _failedLoaded  : int;
		
		private var _loading : Boolean;
		
		public function SourceLoaderManager()
		{
			super();
		}
		
		public function get loading() : Boolean
		{
			return _loading;
		}	
		
		/**
		 * Добавляет загружаемый ресурс в список
		 * @param loaders
		 * 
		 */		
		public function add( loaders : Object ) : void
		{
			if ( ! _loaders )
			{
				_loaders = new Vector.<IAudioDataSource>();
			}
			
			var i     : int = _loaders.length;
			
			if ( loaders as IAudioDataSource )
			{
				_loaders.push( loaders );
			}
			else if ( loaders as Vector.<IAudioDataSource> )
			{
				_loaders.concat( loaders );
			}
			
			while( i < _loaders.length )
			{
				_loaders[ i ].addEventListener( Event.COMPLETE, onComplete );
				_loaders[ i ].addEventListener( ProgressEvent.PROGRESS, onProgress );
				_loaders[ i ].addEventListener( IOErrorEvent.IO_ERROR, onComplete );
				_loaders[ i ].addEventListener( ErrorEvent.ERROR, onComplete );
				
				i ++;
			}
		}
		
		/**
		 * Запускает процесс загрузки всех ресурсов 
		 * 
		 */		
		public function load() : void
		{
			_totalLoaded = 0;
			_successLoaded = 0;
			_failedLoaded = 0;
			
			var i : int = 0;
			
			while( i < _loaders.length )
			{
				_loaders[ i ].load();
				
				i ++;
			}
			
			_loading = true;
		}
		
		/**
		 * Останавливает процесс загрузки всех ресурсов 
		 * 
		 */		
		public function close() : void
		{
			var i : int = 0;
			
			while( i < _loaders.length )
			{
				_loaders[ i ].close();
				
				i ++;
			}
			
			_loading = false;
		}	
		
		public function clear() : void
		{
			if (  _loading )
			 throw new Error( "Clear don't work then SourceLoaderManager is loading! Please, call close first." );	
			
			var i : int = 0;
			
			while( i < _loaders.length )
			{
				_loaders[ i ].removeEventListener( Event.COMPLETE, onComplete );
				_loaders[ i ].removeEventListener( ProgressEvent.PROGRESS, onProgress );
				_loaders[ i ].removeEventListener( IOErrorEvent.IO_ERROR, onComplete );
				_loaders[ i ].removeEventListener( ErrorEvent.ERROR, onComplete );
				
				i ++;
			}
			
			_loaders = null;
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
			var i : int = 0;
			_total = 0;
			_progress = 0;
			
			while( i < _loaders.length )
			{
				_total += _loaders[ i ].total;
				_progress += _loaders[ i ].progress;
				
				i ++;
			}
			
			dispatchEvent( new ProgressEvent( e.type, e.bubbles, e.cancelable, _progress, _total ) );
		}
		
		private function onComplete( e : Event ) : void
		{
			if ( e.type == Event.COMPLETE )
			{
				_successLoaded ++;	
			}	
			else
			{
				_failedLoaded ++;
			}	
			
			_totalLoaded ++;
			
			if ( _totalLoaded == _loaders.length )
			{
				_loading = false;
				clear();
				dispatchEvent( new Event( Event.COMPLETE ) );
			}	
		}	
	}
}