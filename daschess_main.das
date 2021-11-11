require daslib/media
require daslib/decs_boost
// options debugger            // uncomment for debug in VS Code
// require daslib/debug        // uncomment for debug in VS Code

var sound: SoundHandle
var playingSound: PlayingSoundHandle

[decs_template]
struct DrumPad
    key: int
    keyName: string
    color: uint
    pressed: bool

var drums <- [{ auto
    [[DrumPad key=VK_A, color=0x1DBAC5, pressed=false, keyName="A" ]];
    [[DrumPad key=VK_S, color=0xDBB633, pressed=false, keyName="S" ]];
    [[DrumPad key=VK_K, color=0x3ECC20, pressed=false, keyName="K" ]];
    [[DrumPad key=VK_L, color=0xEC4852, pressed=false, keyName="L" ]]
}]

[export]
def initialize(is_hard_reload: bool)
    set_window_title("Chess The Game")
    set_resolution(1280, 720)
    set_font_name("fonts/Inter-SemiBold.ttf")

    if !is_hard_reload
        return

    var size = float2(150, 40)
    var startPos = float2(300, 720 - 80)
    for i in range(length(drums))
        create_entity <| @ ( eid, cmp )
            cmp |> set("eid", eid)
            cmp |> set("size", size)
            cmp |> set("position", startPos + float2((150 + 30) * i, 0))
            cmp |> apply_decs_template(drums[i])

    sound = create_managed_sound("sound/mozart.mp3")
    playingSound = sound |> play_sound()
    commit()

[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()
    decs_stage("input")
    decs_stage("update")

[decs(stage = draw)]
def draw_drumpad_es(var position: float2; var size: float2; var drum: DrumPad)
    if drum.pressed
        fill_rect(position.x - 8f, position.y - 5f, 165f, 50f, 0xFFFFFF)
    fill_rect(position.x, position.y, size.x, size.y, drum.color)
    set_font_size(25)
    text_out(position.x + 65f, position.y + 6f, drum.keyName, drum.pressed ? 0x1E1E1E : 0xFEFBFB)

[decs(stage = input)]
def input_drumpad_es(var drum: DrumPad&)
    drum.pressed = get_key(drum.key)

[export]
def draw
    var playPos = playingSound |> get_sound_play_pos
    var text = "No music play. Reload game(Ctrl+F5)"
    if sound.duration > 0f
        text = "Progress: {(playPos / sound.duration) * 100f}"
    text_out(20, 20, text, 0xFFFFFF)
    decs_stage("draw")
