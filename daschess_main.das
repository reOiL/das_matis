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

enum BlockType
    Empty
    Exist

struct Note
    _type: BlockType

struct NoteLayer
    timeCode: float
    notes: Note[4]

struct Level
    sound : string
    layers: array<NoteLayer>


var level1_layers <- [{ auto
    [[NoteLayer timeCode=10f, notes=[[ auto
            [[Note _type = BlockType Empty]];
            [[Note _type = BlockType Exist]];
            [[Note _type = BlockType Exist]];
            [[Note _type = BlockType Empty]]
        ]]
    ]]
}]

var level1 <- [[Level sound="sound/promo.mp3"]]

var timeDelta = 0f

[export]
def initialize(is_hard_reload: bool)
    set_window_title("The Mantis Game")
    set_resolution(1280, 720)
    set_font_name("fonts/Inter-SemiBold.ttf")
    set_font_size(25)

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

    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        cmp |> set("note_spawn_timer", 0f)
        cmp |> set("note_spawn_time", 0.5f)
        cmp |> set("level_layer", 0)

    sound = create_managed_sound(level1.sound)
    playingSound = sound |> play_sound()
    commit()

[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()
    timeDelta = dt
    decs_stage("input")
    decs_stage("update")

[decs(stage = draw)]
def draw_drumpad_es(position: float2; size: float2; drum: DrumPad)
    if drum.pressed
        fill_rect(position.x - 8f, position.y - 5f, 165f, 50f, 0xFFFFFF)
    fill_rect(position.x, position.y, size.x, size.y, drum.color)
    text_out(position.x + 65f, position.y + 6f, drum.keyName, drum.pressed ? 0x1E1E1E : 0xFEFBFB)

[decs(stage = input)]
def input_drumpad_es(var drum: DrumPad&)
    drum.pressed = get_key(drum.key)

[decs(stage = draw)]
def draw_note_es(note_color: uint; position: float2; size: float2)
    fill_rect(position.x, position.y, size.x, size.y, note_color)

[decs(stage = update)]
def spawn_note_timer(var note_spawn_time: float; var note_spawn_timer: float&; var level_layer: int&)
    if uint(level_layer) >= uint(length(level1_layers))
        return

    let layer = level1_layers[level_layer]
    if layer.timeCode > get_sound_play_pos(playingSound)
        return

    ++level_layer
    let startPos = float2(317, 127)
    let size = float2(115, 40)
    for i in range(length(drums))
        if layer.notes[i]._type == BlockType Empty
            continue

        create_entity <| @ ( eid, cmp )
            cmp |> set("eid", eid)
            cmp |> set("size", size)
            cmp |> set("position", startPos + float2((150 + 30) * i, 0))
            cmp |> set("note_color", drums[i].color)
    commit()

[decs(stage = update)]
def move_note_es(eid: EntityId; note_color: uint; var position: float2&; var size: float2)
    position.y += 200f * timeDelta

    if int(position.y) >= get_screen_height() - int(size.y * 2f)
        delete_entity(eid)

[export]
def draw
    var playPos = playingSound |> get_sound_play_pos
    var text = "No music play. Reload game(Ctrl+F5)"
    if sound.duration > 0f
        text = "Progress: {(playPos / sound.duration) * 100f}"
    text_out(20, 20, text, 0xFFFFFF)
    decs_stage("draw")
