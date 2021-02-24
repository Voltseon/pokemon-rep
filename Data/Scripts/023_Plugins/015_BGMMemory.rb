#==============================================================================
# BGM Pause and Resume
#------------------------------------------------------------------------------
# v1.1 by Boonzeet
# Requires FModEx to work. Place BELOW your FMod Audio & RGSS Linker scripts
#
# Please credit if used
#==============================================================================

module Audio
    module_function
    # modified bgm play function
    def bgm_play(file_name, volume = 100, pitch = 100, position = 0)
      volume = volume * @master_volume / 100
      return @bgm_play.call(file_name, volume, pitch) if(@library != ::FmodEx)
      filename = check_file(file_name)
      bgm = ::FmodEx.bgm_play(filename, volume, pitch)
      if position > 0
        bgm.set_position(position)
      end
      @current_bgm = bgm
      loop_audio(bgm, file_name)
    end
    # gets the play position of the current track
    def bgm_pos
      return @current_bgm ? @current_bgm.get_position : 0
    end
  end
  
  #------------------------------------------------------------------------------
  # Game System edits
  #------------------------------------------------------------------------------
  
  class Game_System
    attr_accessor :bgm_positions
  
    alias initialize_bgmplayback initialize
    def initialize(*args)
      initialize_bgmplayback(*args)
      @bgm_positions = Hash.new(0)
    end
  
    # BGM Position setter
    def bgm_setpos(name, position=0)
      return if !name
      @bgm_positions = Hash.new(0) if !@bgm_positions
      if @bgm_positions[name] && position == 0
        @bgm_positions.delete(name)
      else
        @bgm_positions[name] = position
      end
    end
  
    # BGM Position getter
      def bgm_getpos(name)
      @bgm_positions = Hash.new(0) if !@bgm_positions
          if @bgm_positions.key?(name)
        result = @bgm_positions[name]
              return result
          else
              return 0
          end
    end
  
    # Clear all positions
    def bgm_clearpos
      @bgm_positions = Hash.new(0)
    end
  
    # Get the position of the current playing track
    def bgm_current_getpos
      return 0 if !@playing_bgm
      pos = Audio.bgm_pos
      return pos
    end
  
    # Remembers the position of the current playing track
    def bgm_current_rememberpos
      return if !@playing_bgm
      self.bgm_setpos(@playing_bgm.name, bgm_current_getpos)
    end
  
    def bgm_pause(fadetime=0.0) # :nodoc:
      self.bgm_current_rememberpos
      self.bgm_fade(fadetime) if fadetime>0.0
      @bgm_paused   = true
    end
  
    def bgm_unpause  # :nodoc:
      self.bgm_setpos(@playing_bgm.name, 0) if @playing_bgm
      @bgm_paused   = false
    end
  
    def bgm_resume(bgm) # :nodoc:
      if @bgm_paused
        pos = self.bgm_getpos(bgm.name)
        self.bgm_play_internal(bgm,pos)
        self.bgm_setpos(bgm.name, 0)
        @bgm_paused   = false
      end
    end
  
    def bgm_stop # :nodoc:
      self.bgm_setpos(@playing_bgm.name, 0) if !@bgm_paused
      @playing_bgm  = nil
      Audio.bgm_stop if !@defaultBGM
    end
  
    def bgm_fade(time) # :nodoc:
    if !@bgm_paused && @playing_bgm
      self.bgm_setpos(@playing_bgm.name, 0)
      @playing_bgm = nil
      Audio.bgm_fade((time*1000).floor) if !@defaultBGM
    end
    Audio.bgm_fade((time*1000).floor) if !@defaultBGM   # otherwise music will not fade back in smoothly
  end
  
    def bgm_play_internal(bgm,position=0) # :nodoc:
      @playing_bgm = (bgm==nil) ? nil : bgm.clone
      if bgm!=nil and bgm.name!=""
        if FileTest.audio_exist?("Audio/BGM/"+bgm.name)
          bgm_play_internal2("Audio/BGM/"+bgm.name,bgm.volume,bgm.pitch,position) if !@defaultBGM
        end
      else
        @bgm_position = position if !@bgm_paused
        @playing_bgm = nil
        Audio.bgm_stop if !@defaultBGM
      end
      if @defaultBGM
        bgm_play_internal2("Audio/BGM/"+@defaultBGM.name,@defaultBGM.volume,@defaultBGM.pitch,position)
      end
      Graphics.frame_reset
    end
  end
  
  #------------------------------------------------------------------------------
  # Custom functions
  #------------------------------------------------------------------------------
  
  def pbRememberBGM
    $game_system.bgm_current_rememberpos
  end
  
  def pbRestoreBGM(bgm)
    $game_system.bgm_resume(bgm)
  end
  
  alias pbPrepareBattle_rememberbgm pbPrepareBattle
  def pbPrepareBattle(*args)
    pbRememberBGM
    pbPrepareBattle_rememberbgm(*args)
  end
  