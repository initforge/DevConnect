import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { Strategy } from 'passport-github2';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';

@Injectable()
export class GithubStrategy extends PassportStrategy(Strategy, 'github') {
  constructor(
    private configService: ConfigService,
    private authService: AuthService,
  ) {
    super({
      clientID: configService.get<string>('GITHUB_CLIENT_ID') || 'placeholder',
      clientSecret: configService.get<string>('GITHUB_CLIENT_SECRET') || 'placeholder',
      callbackURL: 'http://localhost:8080/api/auth/github/callback',
      scope: ['user:email'],
    });
  }

  async validate(accessToken: string, refreshToken: string, profile: any, done: Function) {
    const { username, displayName, emails, photos } = profile;
    const user = {
      githubId: profile.id,
      username: username || profile.login,
      displayName: displayName || username || profile.login,
      email: emails[0].value,
      avatarUrl: photos[0].value,
      accessToken,
    };
    
    // Here you would typically find or create the user in your database
    const dbUser = await this.authService.validateGithubUser(user);
    done(null, dbUser);
  }
}
