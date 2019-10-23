package com.audioengine.sequencer.events
{
	import flash.events.Event;
	
	public class SequencerEvent extends Event
	{
		/**
		 * Курсор воспроизведения достиг конца музыкальных семплов на дорожке 
		 */		
		public static const END_MUSIC : String = 'END_MUSIC';
		/**
		 * Курсор воспроизведения достиг конца дорожки 
		 */		
		public static const END : String = 'END';
		/**
		 * Курсор воспроизведения достиг конца границы петли и перешел на startPosition 
		 */		
		public static const END_LOOP : String = 'END_LOOP';
		/**
		 * Изменилось положение курсора воспроизведения 
		 */		
		public static const POSITION_CHANGED : String = 'POSITION_CHANGED';
		/**
		 * Изменилась длина микса 
		 */		
		public static const DURATION_CHANGED : String = 'DURATION_CHANGED';
		/**
		 * Добавление семпла на дорожку 
		 */		
		public static const ADD_SAMPLE : String = 'ADD_SAMPLE';
		/**
		 * Удаление семпла с дорожки 
		 */		
		public static const REMOVE_SAMPLE : String = 'REMOVE_SAMPLE';
		/**
		 * Произошли какие то изменения связанные с семплами, например добавление/удаление/изменение размера и т.д.
		 */		
		public static const SAMPLE_CHANGE : String = 'SAMPLE_CHANGE';
		/**
		 * Началась запись 
		 */		
		public static const START_RECORDING : String = 'START_RECORDING';
		/**
		 * Началось воспроизведение 
		 */		
		public static const START_PLAYING : String = 'START_PLAYING';
		/**
		 * Воспроизведение было остановлено 
		 */		
		public static const STOPPED : String = 'STOPPED';
		/**
		 * Все дорожки и все семплы были очищены 
		 */		
		public static const CLEAR : String = 'CLEAR';
		/**
		 * Загружен новый проект 
		 */		
		public static const PROJECT_CHANGED : String = 'PROJECT_CHANGED';
		/**
		 * Изменился параметр микшера 
		 */		
		public static const MIXER_PARAM_CHANGED : String = 'MIXER_PARAM_CHANGED';
		/**
		 * Изменилась стартовая позиция петли, конечная позиция петли или loop on/off
		 */		
		public static const LOOP_CHANGED : String = 'LOOP_CHANGED';
		/**
		 *Из палитры были удалены не использованные в проекте семплы 
		 */		
		public static const PALETTE_COMPACTED : String = 'PALETTE_COMPACTED';
		
		public var pos       : Number;
		public var changedBy : String;
		
		public function SequencerEvent( type:String, pos : Number = NaN, changedBy : String = 'audioengine' )
		{
			super( type, true, false);
			this.pos = pos;
			this.changedBy = changedBy;
		}
		
		override public function clone() : Event
		{
			return new SequencerEvent( type, pos, changedBy );
		}	
	}
}