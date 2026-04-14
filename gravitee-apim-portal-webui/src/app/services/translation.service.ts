/*
 * Copyright (C) 2015 The Gravitee team (http://gravitee.io)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { Injectable } from '@angular/core';
import { addTranslations, setLanguage } from '@gravitee/ui-components/src/lib/i18n';
import { TranslateService } from '@ngx-translate/core';
import { Title } from '@angular/platform-browser';

import { environment } from '../../environments/environment';

const RTL_LANGS = new Set(['fa', 'ar', 'he', 'ur']);
export const LOCALE_STORAGE_KEY = 'gravitee-portal-locale';

@Injectable({
  providedIn: 'root',
})
export class TranslationService {
  constructor(
    private translateService: TranslateService,
    private titleService: Title,
  ) {}

  applyDocumentDirection(lang: string) {
    document.documentElement.dir = RTL_LANGS.has(lang) ? 'rtl' : 'ltr';
    document.documentElement.lang = lang;
  }

  private resolveInitialLang(): string {
    const defaultLang = environment.locales[0];
    const savedLang = localStorage.getItem(LOCALE_STORAGE_KEY);
    if (savedLang && environment.locales.includes(savedLang)) {
      return savedLang;
    }
    const browserLang = this.translateService.getBrowserLang();
    return environment.locales.includes(browserLang) ? browserLang : defaultLang;
  }

  load() {
    return new Promise(resolve => {
      this.translateService.addLangs(environment.locales);
      this.translateService.setDefaultLang(environment.locales[0]);
      const lang = this.resolveInitialLang();
      this.translateService.use(lang).subscribe(translations => {
        setLanguage(lang);
        addTranslations(lang, translations, lang);
        this.applyDocumentDirection(lang);
        this.translateService.get('site.title').subscribe(title => this.titleService.setTitle(title));
        resolve(true);
      });
    });
  }
}
