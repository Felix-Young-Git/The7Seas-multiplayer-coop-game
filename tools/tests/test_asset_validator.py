from PIL import Image

from asset_validator import check_naming, check_png_sizes, check_references, main


def make_png(path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGBA", size).save(path)


def test_flags_bad_file_name(tmp_path):
    make_png(tmp_path / "art" / "Tree Sprite.png", (16, 16))
    issues = check_naming(tmp_path)
    assert len(issues) == 1
    assert issues[0].check == "naming"


def test_accepts_snake_case_name(tmp_path):
    make_png(tmp_path / "art" / "tree_sprite.png", (16, 16))
    assert check_naming(tmp_path) == []


def test_png_not_multiple_of_tile_size(tmp_path):
    make_png(tmp_path / "player.png", (20, 16))
    issues = check_png_sizes(tmp_path, tile_size=16)
    assert [i.severity for i in issues] == ["warning"]


def test_png_too_large_is_an_error(tmp_path):
    make_png(tmp_path / "huge.png", (4096, 16))
    issues = check_png_sizes(tmp_path, tile_size=16, max_size=2048)
    assert any(i.severity == "error" for i in issues)


def test_broken_reference_in_scene(tmp_path):
    (tmp_path / "tree.tscn").write_text(
        '[ext_resource type="Texture2D" path="res://art/missing.png" id="1"]')
    issues = check_references(tmp_path)
    assert len(issues) == 1
    assert issues[0].severity == "error"


def test_valid_reference_passes(tmp_path):
    make_png(tmp_path / "art" / "tree.png", (16, 16))
    (tmp_path / "tree.tscn").write_text(
        '[ext_resource type="Texture2D" path="res://art/tree.png" id="1"]')
    assert check_references(tmp_path) == []


def test_addons_folder_is_ignored(tmp_path):
    make_png(tmp_path / "addons" / "Some Plugin" / "Bad Name.png", (7, 7))
    assert check_naming(tmp_path) == []
    assert check_png_sizes(tmp_path) == []


def test_main_exit_codes(tmp_path):
    (tmp_path / "a.tscn").write_text('path="res://nope.png"')
    assert main([str(tmp_path)]) == 1  # missing reference is an error

    clean = tmp_path / "clean"
    clean.mkdir()
    assert main([str(clean)]) == 0


def test_reference_with_spaces_in_path(tmp_path):
    make_png(tmp_path / "UI" / "Inventory UI" / "slot.png", (16, 16))
    (tmp_path / "hotbar.tscn").write_text(
        '[ext_resource type="Texture2D" path="res://UI/Inventory UI/slot.png" id="1"]')
    assert check_references(tmp_path) == []


def test_missing_reference_with_spaces_reports_full_path(tmp_path):
    (tmp_path / "hotbar.tscn").write_text(
        '[ext_resource type="Texture2D" path="res://UI/Inventory UI/gone.png" id="1"]')
    issues = check_references(tmp_path)
    assert "res://UI/Inventory UI/gone.png" in issues[0].message