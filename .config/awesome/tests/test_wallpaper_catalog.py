import hashlib
import json
import struct
import unittest
from pathlib import Path
from urllib.parse import parse_qs, urlparse

DIRECTORY = Path(__file__).resolve().parents[1] / 'theme' / 'wallpapers'
PHASES = (
    'night', 'predawn', 'dawn', 'sunrise', 'morning', 'late_morning',
    'noon', 'afternoon', 'golden_hour', 'sunset', 'twilight',
)


def jpeg_dimensions(contents):
    if not contents.startswith(b'\xff\xd8'):
        raise ValueError('Not a JPEG')
    offset = 2
    while offset < len(contents):
        if contents[offset] != 255:
            raise ValueError('Invalid JPEG marker')
        while contents[offset] == 255:
            offset += 1
        marker = contents[offset]
        offset += 1
        length = struct.unpack_from('>H', contents, offset)[0]
        if marker in {192, 193, 194, 195, 197, 198, 199, 201, 202, 203, 205, 206, 207}:
            height, width = struct.unpack_from('>HH', contents, offset + 3)
            return width, height
        if length < 2 or marker in {217, 218}:
            break
        offset += length
    raise ValueError('Missing JPEG dimensions')


class WallpaperCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.images = json.loads((DIRECTORY / 'catalog.json').read_text())['images']

    def test_complete_catalog(self):
        names = [image['file'] for image in self.images]
        self.assertEqual(len(names), len(set(names)))
        self.assertEqual(len(names), 63)
        for condition in ('cloudy', 'rain', 'storm', 'fog', 'snow'):
            for phase in PHASES:
                self.assertIn(f'weather/{condition}/{phase}.jpg', names)
        for name in ('am_01', 'am_02', 'am_03', 'am_04', 'pm_03_30', 'pm_04', 'pm_04_30', 'pm_11'):
            self.assertIn(name + '.jpg', names)

    def test_weather_phases_have_distinct_photographs(self):
        weather = [image for image in self.images if image['file'].startswith('weather/')]
        self.assertEqual(len(weather), 55)
        self.assertEqual(len({image['sha256'] for image in weather}), 55)
        self.assertEqual(len({image['source'] for image in weather}), 55)
        catalog_files = {image['file'] for image in self.images}
        installed_files = {str(path.relative_to(DIRECTORY)) for path in DIRECTORY.glob('weather/*/*.jpg')}
        self.assertEqual(installed_files, {name for name in catalog_files if name.startswith('weather/')})

    def test_downloaded_images_are_bounded_valid_jpegs(self):
        for image in self.images:
            with self.subTest(image=image['file']):
                path = DIRECTORY / image['file']
                self.assertTrue(path.resolve().is_relative_to(DIRECTORY.resolve()))
                contents = path.read_bytes()
                self.assertEqual(jpeg_dimensions(contents), (2560, 1600))
                self.assertEqual((image['width'], image['height']), (2560, 1600))
                self.assertLess(len(contents), 2 * 1024 * 1024)
                self.assertEqual(hashlib.sha256(contents).hexdigest(), image['sha256'])

    def test_sources_credits_and_server_side_resize_are_recorded(self):
        for image in self.images:
            with self.subTest(image=image['file']):
                self.assertTrue(image['author'].strip())
                self.assertTrue(image['source'].startswith('https://unsplash.com/photos/'))
                self.assertEqual(image['license'], 'https://unsplash.com/license')
                url = urlparse(image['download'])
                self.assertEqual(url.scheme, 'https')
                self.assertEqual(url.netloc, 'images.unsplash.com')
                self.assertTrue(url.path.startswith('/photo-'))
                query = parse_qs(url.query)
                self.assertEqual(query['w'], ['2560'])
                self.assertEqual(query['h'], ['1600'])
                self.assertEqual(query['fm'], ['jpg'])
                self.assertEqual(query['fit'], ['crop'])


if __name__ == '__main__':
    unittest.main()
