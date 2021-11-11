require daslib/media
require daslib/decs_boost
require conf/level
require fio

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
    beforePressed: bool

var drums <- [{ auto
    [[DrumPad key=VK_A, color=0x1DBAC5, pressed=false, keyName="A" ]];
    [[DrumPad key=VK_S, color=0xDBB633, pressed=false, keyName="S" ]];
    [[DrumPad key=VK_K, color=0x3ECC20, pressed=false, keyName="K" ]];
    [[DrumPad key=VK_L, color=0xEC4852, pressed=false, keyName="L" ]]
}]

var timeDelta = 0f
var
    failedImage: ImageHandle
    okImage: ImageHandle

[export]
def initialize(is_hard_reload: bool)
    set_window_title("The Mantis Game")
    set_resolution(1280, 720)
    set_font_name("fonts/Inter-SemiBold.ttf")
    set_font_size(25)

    okImage <- create_managed_image("img/icon/ok.png")
    make_image_color_transparent(okImage, get_pixel(okImage, 0, 0))
    failedImage <- create_managed_image("img/icon/failed.png")
    make_image_color_transparent(failedImage, get_pixel(failedImage, 0, 0))

    if !is_hard_reload
        return

    var size = float2(150, 40)
    var startPos = float2(300, 720 - 80)
    for i in range(length(drums))
        create_entity <| @ ( eid, cmp )
            cmp |> set("eid", eid)
            cmp |> set("size", size)
            cmp |> set("drum_index", i)
            cmp |> set("position", startPos + float2((150 + 30) * i, 0))
            cmp |> apply_decs_template(drums[i])

    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        cmp |> set("level_layer", 0)
        cmp |> set("level_velocity", level1.velocity)

    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        cmp |> set("stats_miss", 0)
        cmp |> set("stats_pass", 0)

    sound = create_managed_sound(level1.sound)
    playingSound = sound |> play_sound()
    // enable_edit_mode()
    commit()

def enable_edit_mode()
    query <| $ (eid: EntityId; level_layer: int)
        delete_entity(eid)

    query <| $ (eid: EntityId; note_color: uint)
        delete_entity(eid)

    create_entity <| @ ( eid, cmp )
        cmp |> set("eid", eid)
        cmp |> set("edit_mode", true)
    playingSound |> set_sound_play_pos(sound.duration)

[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()

    if get_key(VK_F1)
        enable_edit_mode()

    timeDelta = dt
    decs_stage("input")
    decs_stage("update")
    decs_stage("collision_update")

[decs(stage = draw)]
def draw_drumpad_es(position: float2; size: float2; drum: DrumPad)
    if drum.pressed
        fill_rect(position.x - 8f, position.y - 5f, 165f, 50f, 0xFFFFFF)
    fill_rect(position.x, position.y, size.x, size.y, drum.color)
    text_out(position.x + 65f, position.y + 6f, drum.keyName, drum.pressed ? 0x1E1E1E : 0xFEFBFB)

[decs(stage = input)]
def input_drumpad_es(var drum: DrumPad&)
    drum.beforePressed = drum.pressed
    drum.pressed = get_key(drum.key)

[decs(stage = draw)]
def draw_note_es(note_color: uint; position: float2; size: float2)
    fill_rect(position.x, position.y, size.x, size.y, note_color)

[decs(stage = update)]
def spawn_note_timer(level_velocity: float;
                     var level_layer: int&)
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
            cmp |> set("note_index", i)
            cmp |> set("velocity", level_velocity)

[decs(stage = update)]
def move_note_es(eid: EntityId;
                 note_color: uint;
                 velocity: float;
                 var position: float2&;
                 var size: float2)
    position.y += velocity * timeDelta

    if int(position.y) >= get_screen_height() - int(size.y * 1.2f)
        delete_entity(eid)
        create_entity <| @ ( eid2, cmp )
            cmp |> set("eid", eid2)
            cmp |> set("success", false)
            cmp |> set("live_time", 1f)
            cmp |> set("position", position + float2(50f, -50f))
        query <| $ (var stats_miss: int&)
            stats_miss++

[decs(stage=collision_update)]
def note_collision_with_drum(eid: EntityId; note_index: int; position: float2; size: float2)
    let notePosition = position
    query <| $ (drum_index: int; position: float2; drum: DrumPad)
        if drum_index != note_index || !drum.pressed || drum.beforePressed
            return

        if position.y - (notePosition.y + size.y) <= 0f
            delete_entity(eid)
            create_entity <| @ ( eid2, cmp )
                cmp |> set("eid", eid2)
                cmp |> set("success", true)
                cmp |> set("live_time", 1f)
                cmp |> set("position", position + float2(50f, -50f))
            query <| $ (var stats_pass: int&)
                stats_pass++

[decs(stage=draw)]
def draw_stats_es(stats_miss: int; stats_pass: int)
    text_out(20, 50, "Miss: {stats_miss} / Pass: {stats_pass}", 0xFFFFFF)

[decs(stage=update)]
def decal_move_es(eid: EntityId;
                  success: bool;
                  var position: float2&;
                  var live_time: float&)
    if live_time <= 0f
        delete_entity(eid)
        return
    live_time -= timeDelta
    position.y -= 100f * timeDelta * (2f - live_time)

[decs(stage=draw)]
def draw_decals_es(success: bool; position: float2)
    draw_image(success ? okImage : failedImage, position.x, position.y, make_color(1f, 1f, 1f))

[export]
def draw
    var playPos = playingSound |> get_sound_play_pos
    var text = "No music play. Reload game(Ctrl+F5)"
    if sound.duration > 0f
        text = "Progress: {playPos} of {sound.duration}"
    text_out(20, 20, text, 0xFFFFFF)
    decs_stage("draw")

var edit_mode_tb: array<NoteLayer>

def add_to_edit_mode_table()
    var exist = false
    var timeCode = get_sound_play_pos(playingSound)
    var layer = [[NoteLayer timeCode=timeCode, notes=[[ auto
            [[Note _type = BlockType Empty]];
            [[Note _type = BlockType Empty]];
            [[Note _type = BlockType Empty]];
            [[Note _type = BlockType Empty]]
        ]]
    ]]

    var len = length(edit_mode_tb)
    var modifOld = false
    if len > 0 && (timeCode - edit_mode_tb[len - 1].timeCode) <= 0.03
        timeCode = edit_mode_tb[len - 1].timeCode
        layer = edit_mode_tb[len - 1]
        modifOld = true

    query <| $ (drum: DrumPad; drum_index: int)
        if !drum.pressed
            return

        if drum.beforePressed
            return

        layer.notes[drum_index]._type = BlockType Exist
        exist = true

    if !exist || modifOld
        return
    //todo: calc from velocity
    //todo: compress note to one simple if time isn't large

    edit_mode_tb |> push(layer)

def flush_edit_mode_table()
    var str = "var level1_layers <- [\{ auto\n"
    for i in iter_range(edit_mode_tb)
        var node = edit_mode_tb[i]
        // -1.91f calculate by formula t = s/v(where s lv velocity)
        str += "    [[NoteLayer timeCode={node.timeCode}-1.91f, notes=[[ auto\n"
        for j in iter_range(node.notes)
            str += "            [[Note _type = BlockType {node.notes[j]._type}]]"
            if j != 3
                str += ";"
            str += "\n"
        str += "        ]]\n"
        str += "    ]]"
        if i != length(edit_mode_tb) - 1
            str += ";"
        str += "\n"
    str += "}]\n";
    var ff = fopen("editmode.gen_das", "w")
    ff |> fprint(str)
    ff |> fclose
/*
Edit mode
*/
[decs(stage = input)]
def edit_mode_input_es(edit_mode: bool)
    if get_key(VK_SPACE)
        playingSound = sound |> play_sound()

    if get_key(VK_F3)
        flush_edit_mode_table()
    add_to_edit_mode_table()

[decs(stage = draw)]
def edit_mode_debug_text_draw(edit_mode: bool)
    text_out(20, 60, "Edit mode", 0xFFFFFF)