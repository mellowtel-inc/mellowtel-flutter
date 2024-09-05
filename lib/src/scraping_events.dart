import 'package:mellowtel/src/exceptions.dart';
import 'package:mellowtel/src/model/scrape_result.dart';

typedef OnScrapingResult = void Function(ScrapeResult result);
typedef OnScrapingException = void Function(ScrapingException error);
typedef OnStorageException = void Function(MellowtelException error);
typedef OnOptIn = void Function();
typedef OnOptOut = void Function();
